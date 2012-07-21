package {
	import d2actions.FightOutput;
	import d2api.ChatApi;
	import d2api.PlayedCharacterApi;
	import d2api.SystemApi;
	import d2data.ItemWrapper;
	import d2enums.ChatActivableChannelsEnum;
	import d2hooks.ChatServer;
	import d2hooks.ChatServerCopy;
	import d2hooks.ChatServerCopyWithObject;
	import d2hooks.ChatServerWithObject;
	import d2hooks.GameStart;
	import flash.display.Sprite;

	public class MultiAccountChat extends Sprite
	{
		//::///////////////////////////////////////////////////////////
		//::// Properties
		//::///////////////////////////////////////////////////////////
		
		// APIs
		public var sysApi:SystemApi; // addHook, sendAction
		public var playerApi:PlayedCharacterApi; // GetPlayedCharacterInfo
		public var chatApi:ChatApi; // newChatItem
		
		// Components
		[Module (name="MultiAccountManager")]
		public var modMAM : Object; // modMultiAccountManager
		
		// Constants
		private const sendPVKey:String = "mac_sendPV"
		private const itemIndexCode:String = String.fromCharCode(65532);
		
		//::///////////////////////////////////////////////////////////
		//::// Public methods
		//::///////////////////////////////////////////////////////////
		
		public function main() : void
		{
			sysApi.addHook(GameStart, onGameStart);
			sysApi.addHook(ChatServer, onChatServer);
			sysApi.addHook(ChatServerWithObject, onChatServerWithObjects);
			sysApi.addHook(ChatServerCopy, onChatServerCopy);
			sysApi.addHook(ChatServerCopyWithObject, onChatServerCopyWithObjects);
		}
		
		public function unload() : void
		{
			// hack: Actually the module management system doesn't seem to track
			// module dependencies when unload modules, so we need this test
			
			// modMAM.unregister(sendPVKey);
		}
		
		public function sendPV(infos:Object) : void
		{
			var objects:Vector.<Object> = infos.objects;
			var message:String = infos.message;
			var senderId:int = infos.senderId;
			var receiverId:int = infos.receiverId;
			
			if (playerApi.getPlayedCharacterInfo().id == senderId)
				return;
				
			if (playerApi.getPlayedCharacterInfo().id == receiverId)
				return;
			
			/* Disabled
			if (objects.length)
			{
				var position:int;
				for (var ii:int = 0;  ii < objects.length; ii++)
				{
					position = message.indexOf(itemIndexCode);
					if (position == -1)
						break;
					
					message = message.substr(0, position)
						+ this.chatApi.newChatItem(objects[ii])
						+ message.substr(position + 1);
				}
			}
			// */
			
			sysApi.sendAction(new FightOutput(
					message,
					ChatActivableChannelsEnum.PSEUDO_CHANNEL_PRIVATE
					));
		}

		//::///////////////////////////////////////////////////////////
		//::// Events
		//::///////////////////////////////////////////////////////////
		
		private function onGameStart() : void
		{
			modMAM.register(sendPVKey, this.sendPV);
		}
		
		// Receive message without object
		private function onChatServer(
				channel:int,
				senderId:int,
				senderName:String,
				message:String,
				timestamp:Number,
				fingerprint:String,
				isAdmin:Boolean
				) : void
		{
			processLine(channel, senderId, senderName, 0, "", message,
				timestamp, fingerprint, null, false, isAdmin);
		}
		
		// Receive message with object(s)
		private function onChatServerWithObjects(
				channel:int,
				senderId:int,
				senderName:String,
				message:String,
				timestamp:Number,
				fingerprint:String,
				objects:Object
				) : void
		{
			processLine(channel, senderId, senderName, 0, "", message,
				timestamp, fingerprint, objects);
		}
		
		// Send message without object
		private function onChatServerCopy(
				channel:int,
				receiverName:String,
				message:String,
				timestamp:Number,
				fingerprint:String,
				receiverId:int
				) : void
		{
			processLine(channel, 0, "", receiverId, receiverName, message,
				timestamp, fingerprint);
		}
		
		// Send message with object(s)
		private function onChatServerCopyWithObjects(
				channel:int,
				receiverName:String,
				message:String,
				timestamp:Number,
				fingerprint:String,
				receiverId:int,
				objects:Object
				) : void
		{
			processLine(channel, 0, "", receiverId, receiverName, message,
				timestamp, fingerprint, objects);
		}
		
		private function processLine(
				channel:int,
				senderId:int,
				senderName:String,
				receiverId:int,
				receiverName:String,
				message:String,
				timestamp:Number,
				fingerprint:String,
				objects:Object = null,
				isSpeakingItem:Boolean = false,
				siAdmin:Boolean = false
				) : void
		{
			if (channel != ChatActivableChannelsEnum.PSEUDO_CHANNEL_PRIVATE)
				return;
			
			if (senderId == 0)
				senderName = playerApi.getPlayedCharacterInfo().name;
			
			if (receiverId == 0)
				receiverName = playerApi.getPlayedCharacterInfo().name;
			
			var infos:Object = new Object();
			infos.senderId = senderId;
			infos.receiverId = receiverId;
			infos.message = "de <b>" + senderName + "</b> à <b>" + receiverName
				+ "</b>: " + message;
			
			var objectsTmp:Vector.<ItemWrapper> = new Vector.<ItemWrapper>();
			for each (var item:ItemWrapper in objects)
				objectsTmp.push(item);
			
			infos.objects = objectsTmp;
			
			modMAM.sendOther(sendPVKey, infos);
		}
			
		
		//::///////////////////////////////////////////////////////////
		//::// Debug
		//::///////////////////////////////////////////////////////////
		
		private function traceDofus(str:String) : void
		{
			sysApi.log(2, str);
		}
	}
}
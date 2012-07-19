package {
	import d2actions.FightOutput;
	import d2api.ChatApi;
	import d2api.PlayedCharacterApi;
	import d2api.SystemApi;
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
		public var chatApi:ChatApi; //
		
		// Components
		[Module (name="MultiAccountManager")]
		public var modMAM : Object; // modMultiAccountManager
		
		// Constants
		private const sendPVKey:String = "mac_sendPV"
		
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
			if (playerApi.getPlayedCharacterInfo().id == infos.senderId)
				return;
				
			if (playerApi.getPlayedCharacterInfo().id == infos.receiverId)
				return;
			// */
				
			//infos.message = chatApi.unEsca
			
			sysApi.sendAction(new FightOutput(
					"de <b>" + infos.senderName + "</b> à <b>" +
						infos.receiverName + "</b>: " +
						infos.message,
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
				
			var infos:InfosMessage = new InfosMessage();
			infos.message = message;
			
			if (senderId != 0)
				infos.senderName = senderName;
			else
				infos.senderName = playerApi.getPlayedCharacterInfo().name;
			
			infos.senderId = senderId;
			
			if (receiverId != 0)
				infos.receiverName = receiverName;
			else
				infos.receiverName = playerApi.getPlayedCharacterInfo().name;
			
			infos.receiverId = receiverId;
				
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

class InfosMessage extends Object
{
	public var message:String;
	public var senderName:String;
	public var senderId:int;
	public var receiverName:String;
	public var receiverId:int;
	public var links:Object;
}

package
{
	import d2actions.FightOutput;
	import d2api.ChatApi;
	import d2api.DataApi;
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
	
	/**
	 * The main class of the module. Dispatch the dialogues through the
	 * different accounts.
	 * 
	 * @author Relena
	 */
	public class MultiAccountChat extends Sprite
	{
		//::///////////////////////////////////////////////////////////
		//::// Properties
		//::///////////////////////////////////////////////////////////
		
		// APIs
		/**
		 * @private
		 */
		public var sysApi:SystemApi; // addHook, sendAction
		/**
		 * @private
		 */
		public var playerApi:PlayedCharacterApi; // GetPlayedCharacterInfo
		/**
		 * @private
		 */
		public var chatApi:ChatApi; // newChatItem
		/**
		 * @private
		 */
		public var dataApi:DataApi; // getItemWrapper
		
		// Components
		[Module(name = "MultiAccountManager")]
		/**
		 * MultiAccountManager module reference.
		 */
		public var modMAM:Object; // modMultiAccountManager
		
		[Module(name = "Ankama_Common")]
		/**
		 * Ankama_Common module reference.
		 */
		public var modCommon:Object;
		
		// Constants
		private const sendPVKey:String = "mac_sendPV"
		private const itemIndexCode:String = String.fromCharCode(65532);
		
		//::///////////////////////////////////////////////////////////
		//::// Methods
		//::///////////////////////////////////////////////////////////
		
		/**
		 * Initialize the module.
		 */
		public function main():void
		{
			sysApi.addHook(GameStart, onGameStart);
			sysApi.addHook(ChatServer, onChatServer);
			sysApi.addHook(ChatServerWithObject, onChatServerWithObjects);
			sysApi.addHook(ChatServerCopy, onChatServerCopy);
			sysApi.addHook(
				ChatServerCopyWithObject, onChatServerCopyWithObjects);
		}
		
		/**
		 * Uninitialize the module.
		 */
		public function unload():void
		{
			// hack: Actually the module management system doesn't seem to track
			// module dependencies when unload modules, so we need this test
		
			// modMAM.unregister(sendPVKey);
		}
		
		/**
		 * Process and display the message in the chat module.
		 * 
		 * @param	senderId	Sender index.
		 * @param	receiverId	Receiver index.
		 * @param	message	Message to display.
		 * @param	objects	Objects' links in the message.
		 */
		public function sendPV(senderId:int, receiverId:int, message:String,
			objectsGID:Array):void
		{	
			if (playerApi.getPlayedCharacterInfo().id == senderId)
				return;
			
			if (playerApi.getPlayedCharacterInfo().id == receiverId)
				return;
			
			if (objectsGID.length)
			{
				var position:int;
				for each (var GID:int in objectsGID)
				{
					position = message.indexOf(itemIndexCode);
					if (position == -1)
						break;
					
					message = message.substr(0, position)
						+ chatApi.newChatItem(dataApi.getItemWrapper(GID))
						+ message.substr(position + 1);
				}
			}
			
			sysApi.sendAction(new FightOutput(
				message,
				ChatActivableChannelsEnum.PSEUDO_CHANNEL_PRIVATE));
		}
		
		/**
		 * Process and send the message to the different accounts.
		 * 
		 * @param	channel	display channel index.
		 * @param	senderId	Sender index.
		 * @param	senderName	Sender name.
		 * @param	receiverId	Receiver index.
		 * @param	receiverName	Receiver name.
		 * @param	message	Message to display.
		 * @param	timestamp	Timestamp of reception.
		 * @param	fingerprint	Message fingerprint.
		 * @param	objects	Objects' links in the message.
		 * @param	isSpeakingItem ?
		 * @param	isAdmin	?
		 */
		private function processLine(channel:int, senderId:int,
			senderName:String, receiverId:int, receiverName:String,
			message:String, timestamp:Number, fingerprint:String,
			objects:Object = null, isSpeakingItem:Boolean = false,
			isAdmin:Boolean = false):void
		{
			if (channel != ChatActivableChannelsEnum.PSEUDO_CHANNEL_PRIVATE)
				return;
			
			if (senderId == 0)
				senderName = playerApi.getPlayedCharacterInfo().name;
			
			if (receiverId == 0)
				receiverName = playerApi.getPlayedCharacterInfo().name;
			
			message = "de {player," + senderName + "," + senderId + ","
				+ timestamp + "," + fingerprint + "," + channel + "::<b>"
				+ senderName + "</b>} à {player," + receiverName + ","
				+ receiverId + "," + timestamp + "," + fingerprint + ","
				+ channel + "::<b>" + receiverName + "</b>}: " + message;
			
			var objsGID:Array = new Array();
			for each (var object:ItemWrapper in objects)
				objsGID.push(object.objectGID);
			
			modMAM.sendOther(sendPVKey, senderId, receiverId, message, objsGID);
		}
		
		//::///////////////////////////////////////////////////////////
		//::// Events
		//::///////////////////////////////////////////////////////////
		
		/**
		 * GameStart event handler. Register the functions' keys & create config
		 * menu.
		 */
		private function onGameStart():void
		{
			modMAM.register(sendPVKey, this.sendPV);
			modCommon.addOptionItem("module_multiaccountchat",
				"Module - Multi Account Chat",
				"Ces options servent à configurer le module MultiAccountChat",
				"MultiAccountChat::Config");
		}
		
		/**
		 * ChatServer event handler. Follow message to <code>processLine</code>
		 * function.
		 * 
		 * @param	channel	display channel index.
		 * @param	senderId	Sender index.
		 * @param	senderName	Sender name.
		 * @param	message	Message to display.
		 * @param	timestamp	Timestamp of reception.
		 * @param	fingerprint	Message fingerprint.
		 * @param	isAdmin	?
		 */
		private function onChatServer(channel:int, senderId:int,
			senderName:String, message:String, timestamp:Number,
			fingerprint:String, isAdmin:Boolean):void
		{
			processLine(channel, senderId, senderName, 0, "", message,
				timestamp, fingerprint, null, false, isAdmin);
		}
		
		/**
		 * ChatServerWithObjects event handler. Follow message to
		 * <code>processLine</code> function.
		 * 
		 * @param	channel	display channel index.
		 * @param	senderId	Sender index.
		 * @param	senderName	Sender name.
		 * @param	message	Message to display.
		 * @param	timestamp	Timestamp of reception.
		 * @param	fingerprint	Message fingerprint.
		 * @param	objects	Objects' links in the message.
		 */
		private function onChatServerWithObjects(channel:int, senderId:int,
			senderName:String, message:String, timestamp:Number,
			fingerprint:String, objects:Object):void
		{
			processLine(channel, senderId, senderName, 0, "", message,
				timestamp, fingerprint, objects);
		}
		
		/**
		 * ChatServerCopy event handler. Follow message to
		 * <code>processLine</code> function.
		 * 
		 * @param	channel	display channel index.
		 * @param	receiverName	Receiver name.
		 * @param	message	Message to display.
		 * @param	timestamp	Timestamp of reception.
		 * @param	fingerprint	Message fingerprint.
		 * @param	receiverId	Receiver index.
		 */
		private function onChatServerCopy(channel:int, receiverName:String,
			message:String, timestamp:Number, fingerprint:String,
			receiverId:int):void
		{
			processLine(channel, 0, "", receiverId, receiverName, message,
				timestamp, fingerprint);
		}
		
		/**
		 * ChatServerCopyWithObjects event handler. Follow message to
		 * <code>processLine</code> function.
		 * 
		 * @param	channel	display channel index.
		 * @param	receiverName	Receiver name.
		 * @param	message	Message to display.
		 * @param	timestamp	Timestamp of reception.
		 * @param	fingerprint	Message fingerprint.
		 * @param	receiverId	Receiver index.
		 * @param	objects	Objects' links in the message.
		 */
		private function onChatServerCopyWithObjects(channel:int,
			receiverName:String, message:String, timestamp:Number,
			fingerprint:String, receiverId:int, objects:Object):void
		{
			processLine(channel, 0, "", receiverId, receiverName, message,
				timestamp, fingerprint, objects);
		}
		
		//::///////////////////////////////////////////////////////////
		//::// Debug
		//::///////////////////////////////////////////////////////////
		
		/**
		 * Log message.
		 *
		 * @param	str	The string to display.
		 */
		private function traceDofus(str:String):void
		{
			sysApi.log(2, str);
		}
	}
}
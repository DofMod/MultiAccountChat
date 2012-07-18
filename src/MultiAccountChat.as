package {
	import d2actions.FightOutput;
	import d2api.PlayedCharacterApi;
	import d2api.SystemApi;
	import d2enums.ChatActivableChannelsEnum;
	import d2hooks.ChatServer;
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
		
		// Components
		[Module (name="MultiAccountManager")]
		public var modMultiAccountManager : Object;
		
		// Constants
		private const sendPVKey:String = "mac_sendPV"
		
		//::///////////////////////////////////////////////////////////
		//::// Public methods
		//::///////////////////////////////////////////////////////////
		
		public function main() : void
		{
			sysApi.addHook(GameStart, onGameStart);
			sysApi.addHook(ChatServer, onChatServer);
		}
		
		public function unload() : void
		{
			// hack: Actually the module management system doesn't seem to track
			// module dependencies when unload modules, so we need this test
			
			// modMultiAccountManager.unregister(sendPVKey);
		}
		
		public function sendPV(srcId:int, srcName:String, dstName:String, message:String) : void
		{
			if (playerApi.getPlayedCharacterInfo().id == srcId)
				return;
			
			sysApi.sendAction(new FightOutput(
					"de <b>" + srcName + "</b> à <b>" + dstName + "</b>: " + message,
					ChatActivableChannelsEnum.PSEUDO_CHANNEL_PRIVATE
					));
		}

		//::///////////////////////////////////////////////////////////
		//::// Events
		//::///////////////////////////////////////////////////////////
		
		private function onGameStart() : void
		{
			modMultiAccountManager.register(sendPVKey, this.sendPV);
		}
		
		private function onChatServer(
				channel:int,
				characterId:int,
				characterName:String,
				message:String,
				arg4:Number,
				arg5:String,
				arg6:Boolean
				) : void
		{
			if (channel == ChatActivableChannelsEnum.PSEUDO_CHANNEL_PRIVATE)
			{
				modMultiAccountManager.sendOther(sendPVKey, characterId, characterName, playerApi.getPlayedCharacterInfo().name, message);
			}
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

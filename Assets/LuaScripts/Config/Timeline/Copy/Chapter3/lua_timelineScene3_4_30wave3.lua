-- Demo关卡第一波
local config = {

    path = 'Timeline/Copy/Chapter3/Scene3_4_30/Scene3_4_30wave3.prefab',
    assetPath = 'Timeline/Copy/Chapter3/Scene3_4_30/Scene3_4_30wave3.playable',
    track_list = {
		{
            name = 'Animation Track',
            bindingType = 4,
            bindingPath = 'sphere',
            bindingWujiangCamp = false,
            bindingWujiangID = false,
            clip_list = {},
        },
        {
            name = 'Animation Track (1)',
            bindingType = 4,
            bindingPath = 'CM vcam11',
            bindingWujiangCamp = false,
            bindingWujiangID = false,
            clip_list = {},
        },
        {
		   name = 'Cinemachine Track',
            bindingType = 3,
            bindingPath = false,
            bindingWujiangCamp = false,
            bindingWujiangID = false,
            clipingType = 2,
            clip_list = {},
		}
	},	
	
}

return config

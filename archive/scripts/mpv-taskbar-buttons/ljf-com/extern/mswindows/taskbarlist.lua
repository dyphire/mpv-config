
-- Windows 7 taskbar icon extensions (progress bar, custom thumbnail buttons)

require 'extern.mswindows'
local com = require 'extern.mswindows.com'

com.def {
  {"ITaskbarList";
    methods = {
      {'HrInit'};
      {'AddTab', 'void* hwnd'};
      {'DeleteTab', 'void* hwnd'};
      {'ActivateTab', 'void* hwnd'};
      {'SetActiveAlt', 'void* hwnd'};
    };
    iid = '56FDF344-FD6D-11d0-958A006097C9A090';
  };
  {"ITaskbarList2", inherits='ITaskbarList';
    methods = {
      {'MarkFullscreenWindow', 'void* hwnd, bool32'};
    };
    iid = '602D4995-B13A-429b-A66E1935E44F4317';
  };
  {"ITaskbarList3", inherits='ITaskbarList2';
    methods = {
      {'SetProgressValue', 'void* hwnd, uint64_t done, uint64_t total'};
      {'SetProgressState', 'void* hwnd, uint32_t tbpfFlags'};
      {'RegisterTab', 'void* hwndTab, void* hwndMDI'};
      {'UnregisterTab', 'void* hwndTab'};
      {'SetTabOrder', 'void* hwndTab, void* hwndInsertBefore'};
      {'SetTabActive', 'void* hwndTab, void* hwndMDI, uint32_t tbatFlags'};
      {'ThumbBarAddButtons', 'void* hwnd, uint32_t buttons, void* button'};
      {'ThumbBarUpdateButtons', 'void* hwnd, uint32_t buttons, void* button'};
      {'ThumbBarSetImageList', 'void* hwnd, void* himagelist'};
      {'SetOverlayIcon', 'void* hwnd, void* hicon, const wchar_t* description'};
      {'SetThumbnailTooltip', 'void* hwnd, const wchar_t* toolTip'};
      {'SetThumbnailClip', 'void* hwnd, RECT* clip'};
    };
    iid = 'EA1AFB91-9E28-4B86-90E99E9F8A5EEFAF';
  };
}

return {
  clsid = '56FDF344-FD6D-11d0-958A006097C9A090';
  TBPF_NOPROGRESS    = 0;
  TBPF_INDETERMINATE = 0x1;
  TBPF_NORMAL        = 0x2;
  TBPF_ERROR         = 0x4;
  TBPF_PAUSED        = 0x8;
  TBATF_USEMDITHUMBNAIL   = 0x1;
  TBATF_USEMDILIVEPREVIEW = 0x2;
}

using System;
using System.Drawing;

using mpvnet;

class Script
{
    public Script()
    {
        var form = MainForm.Instance;
        form.Invoke(new Action(() => form.ContextMenu.Font = new Font("微软雅黑", 10)));
    }
}
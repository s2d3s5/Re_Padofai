using Godot;
using Godot.Collections;
using System;

// 重点：文件名 playmanger.cs → 类名必须是 playmanger，大小写完全一致
public partial class PlayManger : Node
{
    // 全部变量加 [Export] 保证GDScript可读取
    [Export] public int ballpos = 0;
    [Export] public string doing = "none";
    private AudioStreamPlayer muice_node;
    [Export] public float[] times = new float[] { 0.0f };
    [Export] public double cutting_time = 0.0;
    [Export] public float offest = 0f;
    [Export] public float f_bpm = 120f;

    private VideoStreamPlayer video_player;
    private bool video_loop=false;
    private float video_pos=0.0f;

    private int render_fps=30;
    private bool render_mode=false;
    private float render_time;

    // 导出节点，编辑器拖拽绑定
    [Export] public AudioStreamPlayer muice;
    [Export] public AudioStreamPlayer hit;
    [Export] public Node storageNode; // 对应 ../存储

    // 录制分辨率
    [Export] private Vector2I _renderSize = new Vector2I(1280, 720);
    // 输出视频文件名
    [Export] private string _outputVideoPath = "render_out.mp4";
    private string writepath="user://lost";

    // 完全对应 gd signal place_tile / start_to_play
    [Signal]
    public delegate void place_tileEventHandler();
    [Signal]
    public delegate void start_to_playEventHandler();
    [Signal]
    public delegate void ball_hittingEventHandler(int ball_pos);
    public Viewport v;
    public override void _Ready()
    {
        render_mode=true;
        ballpos = 0;
        muice_node = muice;
        storageNode = GetNode("../存储");
        hit = GetNode<AudioStreamPlayer>("hit");
        muice_node = GetNode<AudioStreamPlayer>("muice");
        video_player=GetNode<VideoStreamPlayer>("Camera2D/video");
        v=GetViewport();
    }

    public void _on_play_pressed()
    {
        re_time();
        ballpos = 0;
        doing = "play";
        Dictionary adofai_data = storageNode.Get("adofai_data").As<Dictionary>();
        if (adofai_data.Count != 0)
        {
            times = adofai_data["times"].As<float[]>();
            muice_node.Stream = adofai_data["audio"].As<AudioStream>();
            video_player.Set("stream",adofai_data["video_stream"].As<Resource>());

            Dictionary settingDict = adofai_data["setting"].As<Dictionary>();
            offest = settingDict["offset"].As<float>() / 1000f;
            f_bpm = settingDict["bpm"].As<float>();
            offest-= 60f / f_bpm;
            video_pos=settingDict["vidOffset"].As<float>() / 1000f;
            video_pos+=offest;

            EmitSignal("place_tile");
            EmitSignal("start_to_play");
            _on_start_to_play();
            video_player.Call("set_stream_position",video_pos);
            GD.Print(video_pos);
            video_player.Call("play");
            video_player.Set("loop",settingDict["loopVideo"].As<bool>());
            if (render_mode)
            {
                // 年 月 日 时 分 秒 纯数字，安全无特殊符号
                Godot.Collections.Dictionary timeInfo = Time.GetDatetimeDictFromSystem();

                int year = timeInfo["year"].As<int>();
                int month = timeInfo["month"].As<int>();
                int day = timeInfo["day"].As<int>();
                int hour = timeInfo["hour"].As<int>();
                int minute = timeInfo["minute"].As<int>();
                int second = timeInfo["second"].As<int>();

                string timeStamp = $"{year}{month:D2}{day:D2}_{hour:D2}{minute:D2}{second:D2}";
                string dirName = "re_padofai_workspace_" + timeStamp;

                DirAccess folder = DirAccess.Open(OS.GetTempDir());
                Error e = folder.MakeDir(dirName);

                if (e != Error.Ok)
                {
                    GD.Print("创建失败：", e," ",dirName);
                }
                else
                {
                    // 拼接完整路径
                    writepath = OS.GetTempDir().PathJoin(dirName);
                    GD.Print("工作目录：", writepath);
                }
                render_count=0;
            }
            else
            {
                muice_node.Play();
            }
                
        }
    }
    uint render_count=0;
    public override void _Process(double delta)
    {
        base._Process(delta);
        if (doing=="play"&&render_mode && !(get_time() >= times[ballpos + 1] + offest) )
        {
            render_count++;
            render_time+= (float)(1.0 / render_fps);
            Image i=v.GetTexture().GetImage();
            i.SaveWebp(writepath.PathJoin(render_count.ToString())+".webp",false,2f);
        }
    }

    public void re_time()
    {
        cutting_time = Time.GetUnixTimeFromSystem();
    }

    public float get_time()
    {
        if (render_mode)
            return render_time;
        else
            if (muice_node.Playing)
                return muice_node.GetPlaybackPosition();
            else
                return (float)(Time.GetUnixTimeFromSystem() - cutting_time);
    }

    public async void _on_start_to_play()
    {
        if (doing == "play")
        {
            while (ballpos < times.Length - 1 && doing == "play")
            {
                int a=0;
                while (ballpos < times.Length - 1 && get_time() >= times[ballpos + 1] + offest )
                {
                    ballpos++;
                    if (a<=10)
                        hit.Play();a++;EmitSignal("ball_hitting",ballpos);
                }
                await ToSignal(GetTree(), "process_frame");
            }
        }
    }
}
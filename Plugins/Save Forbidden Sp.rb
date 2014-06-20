#==============================================================================
# ■ 禁止在指定位置存档
#  作者：影月千秋
#  版本：V 1.1
#------------------------------------------------------------------------------
# ● 简介
#   本脚本用于禁止在指定档位上存档
#------------------------------------------------------------------------------
# ● 使用方法
#  插入到其他脚本以下、Main之前，设定NoSave模块中的@N数组
#  事件中可使用add_no_save和remove_no_save来新增/取消被禁用的存档号
#  例【add_no_save(3,7,13)】【remove_no_save(4,2,7)】
#------------------------------------------------------------------------------
# ● 声明
#   本脚本来自【影月千秋】，使用、修改和转载请保留此信息
#==============================================================================
module NoSave
  @N = [0]
    # 这是一个数组 在其中写禁止存档的存档号
      # 以下是正确的填写示例
      #  N = [0,1,2]
      #  N = [5]
      #  N = [3,11,14]
      # 示例结束
end # 请就此止步，不要更改其他地方
class Game_Interpreter;def add_no_save(*id);NoSave.instance_variable_set("@N",
NoSave.instance_variable_get("@N").push(*id).uniq);end;def remove_no_save(*id)
NoSave.instance_variable_set("@N",NoSave.instance_variable_get("@N").delete_if{
|x|id.include?(x)});end;end
class Scene_Save;def on_savefile_ok;super;if !NoSave.instance_variable_get("@N"
).include?(@index) && DataManager.save_game(@index);on_save_success;else;
Sound.play_buzzer;end;end;end
#==============================================================================#
#=====                        =================================================#
           "■ 脚 本 尾"
#=====                        =================================================#
#==============================================================================#
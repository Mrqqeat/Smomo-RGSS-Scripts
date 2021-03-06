#==============================================================================
# ** 物品价格比例
#  作者：影月千秋
#  适用：VA
#------------------------------------------------------------------------------
# * 简介
#    提供物品交易时对价格的一系列处理，比如全体物品售价增加20%、全体物品回收
# （贩卖）价格增加原价的35%、某物品的贩卖价格占原价的70%等等。
#    Github：https://github.com/ShadowMomo/Smomo-RGSS-Scripts
#==============================================================================
# * 使用方法
#   将此脚本插入到其他脚本以下，Main以上
#   在下方设定脚本所使用的开关及变量ID
#   数据库中，在物品的备注栏按照下方的正则式来填写匹配备注
#   游戏中可以通过操作开关和变量来进行价格处理
#
#  * 说明
#   买价：从商店买商品的价格
#   卖价：卖给商店的商品价格
#
#  * 物品的备注
#   在备注中按照正则式填写，默认格式为 <贩卖 XX> ，XX为任意数字，表示这个物品
#  的买价将会是原价的 XX%
#   例：
#    <贩卖 65>
#
#  * Buying变量
#   游戏中更改这个变量的值，则物品买价将为：原价 乘以（1 + 变量值 %）
#
#  * Selling变量
#   改变所有物品卖价占买价的比例，新比例 = 原比例 + 变量值
#   如果物品备注栏做了上述设置（脚本第21行），则原比例即为设置的比例；如果没有，
#  则原比例为50。
#
#  * 其他可选功能
#   见设定区内置说明。
#==============================================================================
# * 更新
#   V 1.2 2014.09.07 新增功能 新功能依赖虚拟日历
#   V 1.1 2014.08.15 新增功能 并规范化
#   V 1.0 2013.12.15 新建
#==============================================================================
# * 声明
#   本脚本来自"影月千秋", 使用/修改/转载请保留此信息。
#==============================================================================

$smomo ||= {}
if $smomo["ItemPriceRate"].nil?
$smomo["ItemPriceRate"] = true

#===============================================================================
# ** Smomo
#===============================================================================
module Smomo
  #=============================================================================
  # ** Smomo::ItemPriceRate
  #=============================================================================
  module ItemPriceRate
    Using = 6
    # 开关ID:启用/禁用脚本功能
    Buying = 7
    # 变量ID:控制 从商店购买物品时 价格增加的比例
    Selling = 8
    # 变量ID:控制 在商店卖出物品时 卖价占原价比例的增量
    Match_Reg = /<贩卖\s+(\d+)>/
    # 匹配物品备注栏的正则式，如果懂的话可以自己改（不建议）
    # 默认： /<贩卖\s+(\d+)>/   匹配举例： <贩卖 21>  其中21可以替换为任意数字
    # 以下是可选功能
    OPTIONAL = {
      profiteer: 1,
      # 在贩卖商品时，如果商店中没有有你要卖的商品（你拥有商品 而商店没有）
      # 你的卖价相对你原卖价的倍数
      # 即：实际卖价 = 卖价 * 该值
      # 设为1 则此功能停用
      limitForCalendar: {
      # 配合虚拟日历系统(http://tinyurl.com/psamf9t)使用
      # 欲使此功能生效，请将虚拟日历系统置于此系统上方
      # 使某物品被买了特定数目之后会停售 直到第二天才恢复
      # 仅对物品有效 对武器和防具无效
        # 物品ID => 限制数目,
        3 => 4,
        6 => 158,
      },
    }
#=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+#
#-------------                     --------------------------------------------#
               "请勿跨过这块区域"
#-------------                     --------------------------------------------#
#+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=#
    if $smomo["Calendar"]
      OPTIONAL[:lfcalendar] = OPTIONAL[:limitForCalendar].clone
      met = ->{OPTIONAL[:lfcalendar].each_key{|i| OPTIONAL[:lfcalendar][i] = 0}}
      Smomo::Calendar.routine.push met
      met.call
    end
  end
end
#==============================================================================
# ** Window_ShopBuy
#==============================================================================
class Window_ShopBuy
  alias :item_price_rate_price :price
  def price(item)
    return item.price unless @price[item]
    if $game_switches[Smomo::ItemPriceRate::Using]
      @price[item] * (100 + $game_variables[Smomo::ItemPriceRate::Buying]) / 100
    else
      item_price_rate_price item
    end
  end
  alias :item_price_rate_make_item_list :make_item_list
  def make_item_list
    item_price_rate_make_item_list
    sio = Smomo::ItemPriceRate::OPTIONAL
    @data.reject!{|item|
      i = item.id
      item.is_a?(RPG::Item) && sio[:lfcalendar][i] &&
      sio[:lfcalendar][i] >= sio[:limitForCalendar][i]
    }
  end
end
#==============================================================================
# ** Scene_Shop
#==============================================================================
class Scene_Shop
  alias :item_price_rate_selling_price :selling_price
  def selling_price
    (if $game_switches[Smomo::ItemPriceRate::Using]
      rate = Smomo::ItemPriceRate::Match_Reg =~ @item.note ? $1.to_i : 50
      rate += $game_variables[Smomo::ItemPriceRate::Selling]
      @buy_window.make_item_list
      prc = @item.price * rate / 100
      prc > buying_price ? buying_price : prc
    else
      item_price_rate_selling_price
    end * (@goods.none?{|g| g[1] == @item.id} ?
    Smomo::ItemPriceRate::OPTIONAL[:profiteer] : 1)).round
  end
  alias :item_price_rate_do_buy :do_buy
  def do_buy(number)
    item_price_rate_do_buy number
    sio = Smomo::ItemPriceRate::OPTIONAL
    if @item.is_a?(RPG::Item) && sio[:lfcalendar][@item.id]
      sio[:lfcalendar][@item.id] += number
    end
  end
  alias :item_price_rate_max_buy :max_buy
  def max_buy
    sio = Smomo::ItemPriceRate::OPTIONAL
    if @item.is_a?(RPG::Item) && sio[:lfcalendar][@item.id]
      new_max = sio[:limitForCalendar][@item.id] - sio[:lfcalendar][@item.id]
      [item_price_rate_max_buy, new_max].min
    else
      item_price_rate_max_buy
    end
  end
end

else
  msgbox "请不要重复加载此脚本 : )\n【物品价格比例 ItemPriceRate】"
end
#==============================================================================#
#=====                        =================================================#
           "脚 本 尾"
#=====                        =================================================#
#==============================================================================#

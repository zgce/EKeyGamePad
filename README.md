EKeyGamePad
===========

Mac OSX上手柄模拟键盘消息转换器

第一次将俺的手柄连上MAC玩下游戏，发现雷曼居然只支持键盘。在AppStore上搜了下，几种好用的手柄模拟居然都要钱才能下。感觉不爽自己写了个模拟程序。

手柄到键盘按键的映射只支持文件方式的配置。配置文件如下
<?xml version="1.0" encoding="UTF-8"?>
<ConvertKey>
    <Aixes>  <!-- 在这里配置手柄方向键 这里的 num = 2 是指手柄方向键的轴向标号标号从零开始记数。如果不知道当前手机的轴标号，请先连上手柄然后打开程序，摇动方向键查看Aix标签中第几个值变化了及变化后的取值-->
        <Aix num="2" value="-1.0" key="V_KEY_LEFT"/>
        <Aix num="2" value="1.0" key="V_KEY_RIGHT"/>
        <Aix num="3" value="-1.0" key="V_KEY_UP"/>
        <Aix num="3" value="1.0" key="V_KEY_DOWN"/>
    </Aixes>
    <Buttons> <!-- 这里配置手柄按键 -->
        <Button num="0" value="1.0" key="V_KEY_U"/>
        <Button num="1" value="1.0" key="V_KEY_S"/>
        <Button num="2" value="1.0" key="V_KEY_B"/>
        <Button num="3" value="1.0" key="V_KEY_R"/>
    </Buttons>
</ConvertKey>

程序默认读取 @APPPATH/Content/Resources/convertkey.xml

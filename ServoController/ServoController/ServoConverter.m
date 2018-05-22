#include "ServoConverter.h"

/*
 * ServoConverter_convert(GamepadStickAxis axis, int value)
 * axis: 更新された要素(GamepadConstants.h 参照)
 * value: 更新後の値
 *
 * ゲームパッドの何らかの要素が更新されると，この関数が呼ばれる．
 * 例えば，左スティックのX軸が移動した場合は axis に LeftStickX，value に移動後の座標が代入され呼び出される．
 * アナログスティックの value が取りうる値は GAMEPAD_MIN から GAMEPAD_MAX まで．
 * 押しボタンの value が取りうる値は 0 か 1．
 *
 * ゲームパッドの入力をもとにサーボの速度を決定したら，ServoConverter_setServoSpeed() を呼び出す．
 * void ServoConverter_setServoSpeed(RDTPPacketComponent servo, int speed)
 * servo: 速度を設定するサーボ
 * speed: 設定する速度
 * 引数 servo には Servo0 から Servo9 を指定する．
 * 今のところ，ロボットアームのサーボは下から順に Servo0，Servo1，Servo2 に設定されている．
 * 参考：ここで設定された速度がメインのプログラム内で 100 Hz でサンプリングされ，実際にサーボの位置が更新される．
 */
void ServoConverter_convert(GamepadStickAxis axis, int value)
{
    /* サンプル：左スティックのX軸の値によって一番下のサーボを制御 */
    switch (axis) { /* どのスティックの値が変化したかを調べるには，switch 文が便利 */
        case LeftStickX:
            /* 左スティックのX軸なら，Servo0 の速度を更新 */
            /* 速度はスティックの座標を 8 ビットに落とした値にしてみる(適当) */
            ServoConverter_setServoSpeed(Servo0, value * INT8_MAX / GAMEPAD_MAX);
            break;
            
        default:
            break;
    }
}

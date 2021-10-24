import Foundation
import Bluetooth
import GATT
import BluetoothLinux

public protocol Service : AnyObject {
    var uuid: BluetoothUUID { get }
}



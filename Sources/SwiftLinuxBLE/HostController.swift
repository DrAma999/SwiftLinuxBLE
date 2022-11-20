import Foundation
import Bluetooth
import GATT
import BluetoothLinux

extension HostController {
    public func newPeripheral() async throws -> GATTPeripheral<HostController, BluetoothLinux.L2CAPSocket> {
        // Setup peripheral
        //let address = try await readDeviceAddress()
        //let serverSocket = try await L2CAPSocket.lowEnergyServer(address: address, isRandom: false, backlog: 1)
        
        let peripheral = GATTPeripheral<HostController, BluetoothLinux.L2CAPSocket>(hostController: self, socket: BluetoothLinux.L2CAPSocket.self)
        peripheral.log = { print("Peripheral Log: \($0)") }
        try await peripheral.start()
//        peripheral.newConnection = {
//           let socket = try serverSocket.waitForConnection()
//           let central = Central(id: socket.address)
//           print("BLE Peripheral: new connection")
//           return (socket, central)
//        }
        return peripheral
    }
}

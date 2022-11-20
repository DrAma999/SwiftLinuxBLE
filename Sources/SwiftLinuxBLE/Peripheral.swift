import Foundation
import Bluetooth
import GATT
import BluetoothLinux

public protocol Peripheral : AnyObject {
    var peripheral: GATTPeripheral<HostController, BluetoothLinux.L2CAPSocket> { get }
    var services: [Service] { get set }
    var characteristicsByHandle: [UInt16: CharacteristicType] { get set }
}

extension Peripheral {
    public func advertise(name: GAPCompleteLocalName, services: [Service], iBeaconUUID: UUID? = nil) async throws {
        // Advertise services and peripheral name
        let serviceUUIDs = GAPIncompleteListOf128BitServiceClassUUIDs(uuids: services.map { UUID(bluetooth: $0.uuid) })
        let encoder = GAPDataEncoder()
        let data = try encoder.encodeAdvertisingData(name, serviceUUIDs)
        try await peripheral.hostController.setLowEnergyScanResponse(data, timeout: .default)
        print("BLE Advertising started")
        
        // Setup iBeacon
        if let iBeaconUUID = iBeaconUUID {
            let rssi: Int8 = 30
            let beacon = AppleBeacon(uuid: iBeaconUUID, rssi: rssi)
            let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
            try await peripheral.hostController.iBeacon(beacon, flags: flags, interval: .min, timeout: .default)
        }
    }
    public func add(service: Service) async throws {
        // Find all the characteristics for the service
        let characteristics = Mirror(reflecting: service).children.compactMap {
            $0.value as? CharacteristicType
        }
        
        let gattCharacteristics = characteristics.map {
            GATTAttribute.Characteristic(uuid: $0.uuid, value: $0.data, permissions: $0.permissions, properties: $0.properties, descriptors: $0.descriptors)
        }
        
        let gattService = GATTAttribute.Service(uuid: service.uuid, primary: true, characteristics: gattCharacteristics)
        let _ = try await peripheral.add(service: gattService)
        
        
        for characteristic in characteristics {
            guard let handle = await peripheral.characteristics(for: characteristic.uuid).last else { continue }
            
            print("Characteristic \(characteristic.uuid) with permissions \(characteristic.permissions) and \(characteristic.descriptors.count) descriptors")
            
            // Register as observer for each characteristic
            characteristic.didSet {
                NSLog("MyPeripheral: characteristic \(characteristic.uuid) did change with new value \($0)")
                //self?.peripheral[characteristic: handle] = $0
            }
          
            characteristicsByHandle[handle] = characteristic
            
        }
        services += [service]      
    }
    
    public func didWrite(_ confirmation: GATTWriteConfirmation<Central>) {
        if var characteristic = characteristicsByHandle[confirmation.handle] {
            characteristic.data = confirmation.value
        }
    }
}

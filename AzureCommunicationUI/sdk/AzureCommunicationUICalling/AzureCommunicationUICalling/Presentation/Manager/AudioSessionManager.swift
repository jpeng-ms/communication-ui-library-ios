//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import AVFoundation
import Combine
import CoreBluetooth

protocol AudioSessionManagerProtocol {

}

// Bluetooth peripheral information
struct CBUUIDs {
    static let kBLEServiceUUID: String = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
    static let kBLECharacteristicUuidTx: String = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
    static let kBLECharacteristicUuidRx: String = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
    static let BLEServiceUUID = CBUUID(string: kBLEServiceUUID)

    // (Property = Write without response)
    static let BLECharacteristicUuidTx = CBUUID(string: kBLECharacteristicUuidTx)
    // (Property = Read/Notify)
    static let BLECharacteristicUuidRx = CBUUID(string: kBLECharacteristicUuidRx)
}

extension AudioSessionManager: CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate {
    func startScanning() {
      // Start Scanning
      centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEServiceUUID])
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("test:: Searching for BLE Devices")
            // Scan for peripherals if BLE is turned on
            startScanning()
        } else {
            // Can have different conditions for all states if needed
            // - print generic message for now, i.e. Bluetooth isn't On
            print("test:: Bluetooth switched off or not initialized")
            // for testing purpose only
//            store.dispatch(action: .localUserAction(.audioDeviceChangeSucceeded(device: getCurrentAudioDevice())))
        }
    }

    // MARK: - CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("test:: Peripheral Is Powered On.")
        case .unsupported:
            print("test:: Peripheral Is Unsupported.")
        case .unauthorized:
            print("test:: Peripheral Is Unauthorized.")
        case .unknown:
            print("test:: Peripheral Unknown")
        case .resetting:
            print("test:: Peripheral Resetting")
        case .poweredOff:
            print("test:: Peripheral Is Powered Off.")
        @unknown default:
            print("test:: Error")
        }
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("test:: \(peripheral.name ?? "nil") iss disconnected")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("test:: \(peripheral.name ?? "nil") is disconnected")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("test:: connected to \(peripheral.name ?? "nil")")
    }

    // MARK: - CBPeripheralDelegate
    func centralManager( _ central: CBCentralManager,
                         didDiscover peripheral: CBPeripheral,
                         advertisementData: [String: Any],
                         rssi RSSI: NSNumber) {
        bluefruitPeripheral = peripheral
        bluefruitPeripheral.delegate = self
        print("test:: Peripheral Discovered: \(peripheral)")
        print("test:: Peripheral name: \(peripheral.name)")
        print("test:: Advertisement Data: \(advertisementData)")
        centralManager?.stopScan()
    }
}

class AudioSessionManager: NSObject, AudioSessionManagerProtocol {

    private var logger: Logger!
    private var store: Store<AppState>!
    private var localUserAudioDeviceState: LocalUserState.AudioDeviceSelectionStatus?
    private var audioSessionState: AudioSessionStatus = .active
    private var audioSessionDetector: Timer?
    var cancellables = Set<AnyCancellable>()
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    private var bluefruitPeripheral: CBPeripheral!

    init(store: Store<AppState>,
         logger: Logger) {
        super.init()
        self.store = store
        self.logger = logger
        let currentAudioDevice = getCurrentAudioDevice()
        self.setupAudioSession()
        store.dispatch(action: .localUserAction(.audioDeviceChangeRequested(device: currentAudioDevice)))
        store.$state
            .sink { [weak self] state in
                self?.receive(state: state)
            }.store(in: &cancellables)
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.main)
    }

    private func receive(state: AppState) {
        audioSessionState = state.audioSessionState.status
        let localUserState = state.localUserState
        let userAudioDeviceState = localUserState.audioState.device
        guard userAudioDeviceState != localUserAudioDeviceState else {
            return
        }
        localUserAudioDeviceState = userAudioDeviceState
        handle(state: userAudioDeviceState)
    }

    private func handle(state: LocalUserState.AudioDeviceSelectionStatus) {
        switch state {
        case .speakerRequested:
            switchAudioDevice(to: .speaker)
        case .receiverRequested:
            switchAudioDevice(to: .receiver)
        case .bluetoothRequested:
            switchAudioDevice(to: .bluetooth)
        case .headphonesRequested:
            switchAudioDevice(to: .headphones)
        default:
            break
        }
    }

    private func setupAudioSession() {
        activateAudioSessionCategory()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
    }

    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch interruptionType {
        case .began:
            startAudioSessionDetector()
            store.dispatch(action: .audioSessionAction(.audioInterrupted))
        case .ended:
            store.dispatch(action: .audioSessionAction(.audioInterruptEnded))
            audioSessionDetector?.invalidate()
        default:
            break
        }

    }

    @objc func handleRouteChange(notification: Notification) {
        debugPrint("test:: handleRouteChange: \(notification.name)")
        let currentDevice = getCurrentAudioDevice()
        guard !hasProcess(currentDevice) else {
            return
        }

        store.dispatch(action: .localUserAction(.audioDeviceChangeSucceeded(device: currentDevice)))
    }

    private func activateAudioSessionCategory() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            let options: AVAudioSession.CategoryOptions = [.allowBluetooth,
                                                           .duckOthers,
                                                           .interruptSpokenAudioAndMixWithOthers,
                                                           .allowBluetoothA2DP]
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: options)
            try audioSession.setActive(true)
        } catch let error {
            logger.error("Failed to set audio session category:\(error.localizedDescription)")
        }
    }

    private func getCurrentAudioDevice() -> AudioDeviceType {
        let audioSession = AVAudioSession.sharedInstance()

        if let output = audioSession.currentRoute.outputs.first {
            switch output.portType {
            case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                debugPrint("test:: getCurrentAudioDevice: bluetooth")
                return .bluetooth
            case .headphones, .headsetMic:
                debugPrint("test:: getCurrentAudioDevice: headphones/headsetMic")
                return .headphones
            case .builtInSpeaker:
                debugPrint("test:: getCurrentAudioDevice: builtInSpeaker")
                return .speaker
            default:
                debugPrint("test:: getCurrentAudioDevice: default receiver")
                return .receiver
            }
        }
        debugPrint("test:: getCurrentAudioDevice: receiver")
        return .receiver
    }

    private func switchAudioDevice(to selectedAudioDevice: AudioDeviceType) {
        let audioSession = AVAudioSession.sharedInstance()

        let audioPort: AVAudioSession.PortOverride
        switch selectedAudioDevice {
        case .speaker:
            audioPort = .speaker
        case .receiver, .headphones, .bluetooth:
            audioPort = .none
        }

        do {
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(audioPort)
            store.dispatch(action: .localUserAction(.audioDeviceChangeSucceeded(device: selectedAudioDevice)))
        } catch let error {
            logger.error("Failed to select audio device, reason:\(error.localizedDescription)")
            store.dispatch(action: .localUserAction(.audioDeviceChangeFailed(error: error)))
        }
    }

    private func hasProcess(_ currentAudioDevice: AudioDeviceType) -> Bool {
        switch (localUserAudioDeviceState, currentAudioDevice) {
        case (.speakerSelected, .speaker),
            (.bluetoothSelected, .bluetooth),
            (.headphonesSelected, .headphones),
            (.receiverSelected, .receiver):
            return true
        default:
            return false
        }
    }

    @objc private func detectAudioSessionEngage() {
        guard AVAudioSession.sharedInstance().isOtherAudioPlaying == false else {
            return
        }

        guard audioSessionState == .interrupted else {
            audioSessionDetector?.invalidate()
            return
        }
        store.dispatch(action: .audioSessionAction(.audioEngaged))
        audioSessionDetector?.invalidate()
    }

    private func startAudioSessionDetector() {
        audioSessionDetector?.invalidate()
        audioSessionDetector = Timer.scheduledTimer(withTimeInterval: 1,
                                                    repeats: true,
                                                    block: { [weak self] _ in
            self?.detectAudioSessionEngage()
        })
    }
}

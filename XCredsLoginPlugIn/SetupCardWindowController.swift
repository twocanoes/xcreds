//
//  SetupCardWindowController.swift
//  XCreds
//
//  Created by Timothy Perfitt on 12/4/24.
//

import Cocoa
import CryptoTokenKit

class SetupCardWindowController: NSWindowController {

    var uid:String?
    var pin:String?
    override func windowDidLoad() {
        super.windowDidLoad()
        guard let readerName = DefaultsOverride.standardOverride.string(forKey: PrefKeys.ccidSlotName.rawValue) else {
            TCSLogWithMark("No ccid slot name")
            return
        }
        let watcher = TKTokenWatcher()


        watcher.setInsertionHandler({ tokenID in
            watcher.addRemovalHandler({ tokenID in
                TCSLogWithMark("card removed")
            }, forTokenID: tokenID)

            let slotNames = TKSmartCardSlotManager.default?.slotNames

            guard let slotNames = slotNames, slotNames.count>0 else {
                return
            }

            if slotNames.contains(readerName) == false {
                TCSLogWithMark("reader \(readerName) not found")
            }
            let slot = TKSmartCardSlotManager.default?.slotNamed(readerName)
            guard let tkSmartCard = slot?.makeSmartCard() else {
                return
            }
            TCSLogWithMark("card inserted")

            let builtInReader = CCIDCardReader(tkSmartCard: tkSmartCard)
            TCSLogWithMark()

            let returnData = builtInReader.sendAPDU(cla: 0xFF, ins: 0xCA, p1: 0, p2: 0, data: nil)
            TCSLogWithMark()
            if let returnData=returnData, returnData.count>2{
                DispatchQueue.main.async {
                    TCSLogWithMark()
                    let hex=returnData[0...returnData.count-3].hexEncodedString()

                    let pinSetWindowController = PinSetWindowController(windowNibName: "PinSetWindowController")
                    let res = NSApp.runModal(for: pinSetWindowController.window!)

                    if res == .OK{
                        self.pin = pinSetWindowController.pin

                    }

                    if res == .cancel {
                        pinSetWindowController.window?.close()
                        return
                    }

                    pinSetWindowController.window?.close()


                    self.uid = hex
                    TCSLogWithMark()
                    self.window?.close()
                    NSApp.stopModal(withCode: NSApplication.ModalResponse.OK)
                }
            }

        })

    }
    
    @IBAction func cancelButtonPressed(_ sender: NSButton) {
        self.window?.close()
        NSApp.stopModal(withCode: .cancel)

    }
}

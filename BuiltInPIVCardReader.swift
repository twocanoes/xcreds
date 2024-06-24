//
//  BuiltInPIVCardReader.swift
//  Smart Card Utility iOS
//
//  Created by timothy perfitt on 8/7/22.
//  Copyright © 2022 Twocanoes Software. All rights reserved.
//

import Foundation
import CryptoTokenKit

enum CardState {
    case NotInserted
    case Inserted
    case Connected  //connected to applet

}

enum SmartCardError:Error{


    case invalidSignature(_ msg:String="invalidSignature",certData:Data=Data())
//    case unsupportedSigningAlgorithm(_ msg:String="unsupportedSigningAlgorithm")
//    case unsupportedHashMechanism(_ msg:String="unsupportedHashMechanism")
//    case noSigners(_ msg:String="noSigners")
//    case invalidData(_ msg:String="invalidData")
//    case invalidHash(_ msg:String="invalidHash")
//    case signingAlgorithm(_ msg:String="signingAlgorithm")
//    case digestAlgorithm(_ msg:String="digestAlgorithm")
//    case connectionError(_ msg:String="connectionError")
//    case cardError(_ msg:String="cardError")
//    case invalidSerialNumber(_ msg:String="invalidSerialNumber")
    case APDUSecurityError
    case APDUInvalidDataError
//    case APDUNotFoundError(pivObject:PIVObject?=nil)
    case APDUAuthenticationBlockedError
    case APDUCommunicationError
    case APDUTransactionError(UInt8)
    case APDUOtherError(UInt8,UInt8)

//    case SmartCardError(_ msg:String="SmartCardError")
//    case other(_ msg:String="SmartCardError",pivObject:PIVObject?=nil)

}

class BuiltInPIVCardReader: NSObject {
//    @objc static let sharedReader = BuiltInPIVCardReader(readerInfo: DiscoveredReaderInfo(name: "Built-In", readerType: .native))
    var tkSmartCard:TKSmartCard
    let semaphore = DispatchSemaphore(value: 0)
    init(tkSmartCard: TKSmartCard) {
        self.tkSmartCard = tkSmartCard
//        super.init(readerInfo: discoveredInfo)
    }
    func connectReader() throws {
//        if tkSmartCard != nil && tkSmartCard?.isValid == false {
//            Log("smartcard is not valid")
//            throw SmartCardError.other("smartcard is not valid")
//        }
////        guard let readerName = readerName else {
////            return (false,.failure(-1, "could not get reader name"))
////        }
////        let slot = TKSmartCardSlotManager.default?.slotNamed(readerName)
////        tkSmartCard = slot?.makeSmartCard()
//
////        var success = false
//        guard let tkSmartCard = tkSmartCard else {
//            Log("No smartcard found. Please verify the smartcard is inserted into the reader")
//            throw SmartCardError.other("No smartcard found. Please verify the smartcard is inserted into the reader")
//        }
////        tkSmartCard.beginSession { sessionSuccess, err in
//////            success = sessionSuccess
////            self.semaphore.signal()
////        }
////        let _ = semaphore.wait(timeout: DispatchTime.now()+10)
    }
    public func sendAPDUFullTransaction(cla:UInt8, ins:UInt8,p1:UInt8,p2:UInt8,data rdata:Data?, le:UInt8?) throws -> Data {
        
        
        guard let data = rdata else {
            throw SmartCardError.APDUInvalidDataError
            
        }
        let sendCla:UInt8  = cla
        var aggregateData = Data()
        var sw1=0x00 as UInt8
        var sw2=0x00 as UInt8
        
        
        guard  let dataReturned = sendAPDU(cla:sendCla,ins: ins, p1: p1, p2:p2 , data: data, le: 0) else {

            TCSLog( "Invalid Data")
            throw SmartCardError.APDUOtherError(sw1,sw2)
        }
        if dataReturned.count < 2  {
            TCSLog( "invalid data")
            throw SmartCardError.APDUOtherError(sw1,sw2)
            
        }
        if (dataReturned.count>2){
            aggregateData.append(dataReturned[0...dataReturned.count-3])
        }
        
        sw1=dataReturned[dataReturned.count-2]
        sw2=dataReturned[dataReturned.count-1]
        
        if (sw1 != 0x90) {
//            if (sw1==0x69 && sw2==0x82){
//                Logging.sharedLogger.printLog( "Security condition not satisfied.")
//                throw SmartCardError.APDUSecurityError
//            }
//            else if (sw1==0x63){
//                throw SmartCardError.APDUTransactionError(sw2)
//                
//            }
//            else if (sw1==0x6a && sw2==0x82){
//                Logging.sharedLogger.printLog( "APDU command returned not found. \(#file):\(#line)")
//                throw SmartCardError.APDUNotFoundError()
//
//            }
//            else if (sw1==0x6a && sw2==0x88){
//                Logging.sharedLogger.printLog( "APDU command returned Referenced data not found. \(#file):\(#line)")
//                throw SmartCardError.APDUNotFoundError()
//            }
//
//            else if (sw1 != 0x61){
//                throw SmartCardError.APDUOtherError(sw1,sw2)
//            }
        }
        
        
        
//        if (dataReturned[dataReturned.count-2]==0x90 ){
//            //we have success. so add data if there and return
//            var certData = Data(aggregateData)
//            
//            var isCompressed = false
//            let responseArray = TKBERTLVRecord.sequenceOfRecords(from: aggregateData)
//            responseArray?.forEach({ currReponse in
//                if (currReponse.tag==0x53){
//                    let certInfo = TKBERTLVRecord.sequenceOfRecords(from: currReponse.value)
//                    certInfo?.forEach({ (cert) in
//                        if cert.tag == 0x70 {
//                            certData = cert.value
//                        }
//                        else if cert.tag == 0x71 && cert.value.count==1 && (cert.value[0] & 0x01) == 0x01 {
//                            isCompressed=true
//                            
//                        }
//                    })
//                }
//                
//            })
//            if (isCompressed==true){
//                certData = (certData as NSData).inflate()!
//            }
//            return certData
//        }
//        
//        if (sw1==0x6a && sw2==0x82){
//            Logging.sharedLogger.printLog( "APDU command returned not found. \(#file):\(#line)")
//            throw SmartCardError.APDUNotFoundError()
//            
//        }
//        else if (sw1==0x6a && sw2==0x88){
//            Logging.sharedLogger.printLog( "APDU command returned not found. \(#file):\(#line)")
//            throw SmartCardError.APDUNotFoundError()
//
//        }
//        else if (sw1==0x69 && sw2==0x82){
//            Logging.sharedLogger.printLog( "Security condition not satisfied.")
//            throw SmartCardError.APDUSecurityError
//        }
//        
//        else if (sw1==0x69 && sw2==0x83){
//            Logging.sharedLogger.printLog( "Authentication blocked. Card may be locked.")
//            throw SmartCardError.APDUAuthenticationBlockedError
//        }
//        else if (sw1 != APDU_STATUS_MORE_DATA) {
//            let apduResponses = APDUResponses()
//            let sw1=Int(data[0])
//            let sw2=Int(data[1])
//            let response = apduResponses.apduResponse(sw1:sw1 , sw2:sw2 )
//            
//            Logging.sharedLogger.printLog( "card error. \(#file):\(#line) \(data.hexEncodedString()) \(response?.info ?? "")")
//            throw SmartCardError.APDUInvalidDataError
//        }
//        else {
//            if (dataReturned.count>4){
//                aggregateData.append(dataReturned[0...dataReturned.count-3])
//            }
//            
//            
//            
//        }
        return Data()
        
    }
    func sendAPDU(cla:UInt8, ins:UInt8,p1:UInt8,p2:UInt8, lcByteLength:UInt8=1,data:Data?,le:UInt16?=nil, leByteLength:UInt8=1) -> Data? {
        var returnData = Data()
        var resp:Data
        var sw:UInt16
        var localLE = 0
        if let le = le {
            localLE = Int(le)
        }
//        guard let tkSmartCard = tkSmartCard else {
//            return nil
//        }ff
        
        tkSmartCard.useCommandChaining=true
        tkSmartCard.beginSession { sessionSuccess, err in
            self.semaphore.signal()
        }
        let _ = semaphore.wait(timeout: DispatchTime.now()+10)

        do{
            tkSmartCard.cla = cla
            (sw,resp) = try tkSmartCard.send(ins: ins, p1: p1, p2: p2, data: data,le:localLE)
            tkSmartCard.endSession()
            returnData.append(resp)
            
            var swData=Data()
            withUnsafePointer(to: &sw) {
                swData.append(UnsafeBufferPointer(start: $0, count: 1))
            }
            let sw1=swData[1]
            let sw2=swData[0]
            returnData.append(sw1)
            returnData.append(sw2)
        }
        catch {
            return nil
        }
        return returnData
    }
    func disconnectCard() {
        if tkSmartCard.isValid == true {
            endSession()
        }


    }

//    func disconnectReader() -> Bool {
//        
//        let _ = super.disconnectReader()
//        return true
//    }
    func endSession() {

        tkSmartCard.endSession()
    }

}

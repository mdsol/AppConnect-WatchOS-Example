//
//  InterfaceController.swift
//  watch-lib-tester-2 WatchKit Extension
//
//  Created by Nathaniel Jacobs on 10/29/19.
//  Copyright © 2019 Medidata Solutions. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController, WKCrownDelegate {
    
    @IBOutlet weak var uploadButton: WKInterfaceButton!
    
    @IBOutlet weak var sizeLabel: WKInterfaceLabel!
    
    var size = 10
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        if rotationalDelta > 0 {
          let newValue = size + 1
        } else if rotationalDelta < 0 {
          let newValue = size - 1
        }
        
         let newValue = size + Int(rotationalDelta*50)
         if newValue < 1 {
             size = 1
         } else if newValue > 1000 {
             size = 1000
         } else {
             size = newValue
         }
         sizeLabel.setText("\(size)MB")
     }
    
    @IBAction func buttonAction(){
        let contentString = "Todd Landman, nevertheless, draws our attention to the fact that democracy and human rights are two different concepts and that there must be greater specificity in the conceptualisation and operationalization of democracy and human rights"
        
        var stringData = contentString.data(using: .utf8)!
        do{
            stringData = try randomData(ofLength:size*1000000)
        }catch{
            
        }
        let filename = "test_file_\(size)" // Files of the same name will be overwritten!  Use a unique filename to avoid collisions.
        
        let action = WKAlertAction(title: "OK", style: WKAlertActionStyle.default) {
            print("Ok")
        }
        
        sizeLabel.setText("Uploading")
        var timeAtPress = Date()
        let completionHandler : AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in
            let t = task as AWSS3TransferUtilityUploadTask
            print(t.request?.description)
            if ((error) != nil){
                
                //handle errors here
                print(t.response?.description)
                print("Upload failed")
                self.sizeLabel.setText("\(self.size)MB")
                print(error!.localizedDescription)
                self.presentAlert(withTitle: "Failed upload!", message: "File upload failure! " + error!.localizedDescription, preferredStyle: WKAlertControllerStyle.alert, actions: [action])
            }else{
                //handle success here
                self.presentAlert(withTitle: "Successful upload!", message: "File uploaded successfully. \(stringData.count/1000000) MB in \(Int(Date().timeIntervalSince(timeAtPress))) seconds", preferredStyle: WKAlertControllerStyle.alert, actions: [action])
                self.sizeLabel.setText("\(self.size)MB")

                print("File uploaded successfully in \(Int(Date().timeIntervalSince(timeAtPress))) seconds")
            }
        }
        

        
        // Send the data!
        EproEndpoint.executeIngestionRequest(medistranoStage: MedistranoStage.production, user: "eprotest@mdsol.com", password: "Password", subjectUuid: "309f0c35-a464-450f-b3fd-2d9c3037041b", data: stringData, filename: filename, completionHandler: completionHandler)
        
    }
    
    public func randomData(ofLength length: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes: bytes)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        crownSequencer.delegate = self

    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func didAppear() {
            crownSequencer.focus()
    }

}

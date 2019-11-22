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
        upload()
    }
    
    func upload(){
        let contentString = "Todd Landman, nevertheless, draws our attention to the fact that democracy and human rights are two different concepts and that there must be greater specificity in the conceptualisation and operationalization of democracy and human rights"
        
        var stringData = contentString.data(using: .utf8)!
        do{
            stringData = try randomData(ofLength:size*1000000)
        }catch{}
        
        // filenames must be alpha numeric characters, as well as -_. (hyphen, underscore and period) in the filename.  No special charecters
        let filename = "test_file_\(size)_MB" // Files of the same name will be overwritten!  Use a unique filename to avoid collisions.
                
        // Send the data!
        EproEndpoint.executeIngestionRequest(medistranoStage: MedistranoStage.production, user: "njacobseprotest@mdsol.com", password: "Password2", subjectUuid: "309f0c35-a464-450f-b3fd-2d9c3037041b", data: stringData, filename: filename, mediUploadable: uploadHandler(withInterface: self))
    }
    
    
    class uploadHandler: MediUploadable {
        var interface: WKInterfaceController
        
        init(withInterface face: WKInterfaceController){
            interface = face
        }
        
        public func uploadCompleted(success: Bool, errorMessage: String, fileName: String) {
            let action = WKAlertAction(title: "OK", style: WKAlertActionStyle.default) { print("Ok") }
            if (success == true) {
                interface.presentAlert(withTitle: "Successful upload!", message: "File uploaded successfully. \(fileName)", preferredStyle: WKAlertControllerStyle.alert, actions: [action])
                print("\(fileName) uploaded successfully")
                
            }else{
                interface.presentAlert(withTitle: "Failed upload!", message: "File upload failure! \(fileName) " + errorMessage, preferredStyle: WKAlertControllerStyle.alert, actions: [action])
                print("\(fileName) upload failed due to \(errorMessage)")
            }
        }
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

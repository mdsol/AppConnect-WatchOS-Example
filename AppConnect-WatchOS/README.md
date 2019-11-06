# AppConnect - WatchOS

## Instructions to install the AppConnect SDK for WatchOS

### 1.  Download the SDK
 - In your project directory run the command `git submodule add https://github.com/mdsol/AppConnect-WatchOS.git`

### 2. Add source files
- In Xcode, right click on your target group.  Press `Add files to [Target Group]`
- Highlight all files and folders in AppConnect-WatchOS.
- Under `Add to targets` check the box to select your targeted WatchOS extension app.

*We don't need xcode to automatically configure a bridging header, although there will be no harm if you accidentily add one.*

### 3.  Configure files
- Navigate to the `Build Settings` for your target app.  Click `Objetive-c Bridging Header` under `Swift Compiler - General` .
- Drag `s3-header.h` into the entry field.  You should see the contents of the field automatically filled out.  Verify that it is correct.
- While still under `Build Settings`,  navigate to `Search Paths`.  Select `Header Search Paths`.  Drag `aws-sdk-ios` into the entry field.  Select the `recursive`  option on the right hand side.

### 4. Run app
- Run the app to confirm all required classes compile.

*In case of errors, ensure your compile sources are correct.  Verify they include all aws files.*

## Code Sample
- To upload sensor data to the Medidata cloud use the following code sample.

        let contentString = "Todd Landman, nevertheless, draws our attention to the fact that democracy and human rights are two different concepts and that there must be greater specificity in the conceptualisation and operationalization of democracy and human rights"
        let stringData = contentString.data(using: .utf8)!
        
        let filename = "test_file2.txt" // Files of the same name will be overwritten!  Use a unique filename to avoid collisions. 
        
        let completionHandler : AWSS3TransferUtilityUploadCompletionHandlerBlock = { (task, error) -> Void in
            let t = task as AWSS3TransferUtilityUploadTask
            print(t.request?.description)
            if ((error) != nil){
                
                //handle errors here
                print(t.response?.description)
                print("Upload failed")
                print(error!.localizedDescription)
            }else{
                //handle success here
                print("File uploaded successfully")
            }
        }
        
        // Send the data!
        EproEndpoint.executeIngestionRequest(medistranoStage: MedistranoStage.production, user: "njacobseprotest@mdsol.com", password: "Password1", subjectUuid: "309f0c35-a464-450f-b3fd-2d9c3037041b", data: stringData, filename: filename, completionHandler: completionHandler)
        

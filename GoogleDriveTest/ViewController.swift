import GoogleAPIClientForREST
import GoogleSignIn
import UIKit

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    private let scopes = [kGTLRAuthScopeDriveFile]
    private let service = GTLRDriveService()
    let userDefaults = UserDefaults.standard
    
    var fileR :GTLRDrive_File = GTLRDrive_File.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error
        {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
            
        } else
        {
            usernameLabel.text = "User = \(user.profile.name)"
            self.service.authorizer = user.authentication.fetcherAuthorizer()
        }
    }
    
    
    func uploadFile()
    {
        var fileData :Data?
        var uploadParameters :GTLRUploadParameters
        
        if let path = Bundle.main.path(forResource: "white-paper", ofType: "pdf", inDirectory: "")
        {
            fileData = FileManager.default.contents(atPath: path)
            let metaData = GTLRDrive_File.init()
            metaData.name = "realmDB.realm"
            
            if let fileData = fileData
            {
                uploadParameters = GTLRUploadParameters.init(data: fileData, mimeType: "application/pdf")
                uploadParameters.shouldUploadWithSingleRequest = false
            }
            else
            {
                print("Error")
                return
            }
            
            
            var query :GTLRDriveQuery
            
            /****
           let theId =  userDefaults.string(forKey: "fileID")
            
            if let id = theId
            {
                var queryCheckExists = GTLRDriveQuery_FilesGet.query(withFileId:  id)
                self.service.executeQuery(queryCheckExists)
                { (ticket, file, error) -> Void  in
                    
                    if error == nil
                    {
                        let theFile :GTLRDrive_File? = file as? GTLRDrive_File
                        if let theFile = theFile
                        {
                            print("File ID = \(theFile.identifier)")
                            print("OK FILE Exists")
                        }
                    }
                    else
                    {
                        print("Error = \(error?.localizedDescription)")
                        print("Can't find file removing stored fileID")
                        self.userDefaults.removeObject(forKey: "fileID")
                    }
                }
            }
            *****/
            
            /***
            // exists?
            if let id = userDefaults.string(forKey: "fileID")
            {
                // just update already exists
                // check on drive first probably
                query = GTLRDriveQuery_FilesUpdate.query(withObject: metaData, fileId: id, uploadParameters: uploadParameters)
            }
            else
            {
                // no stored id so create new
                query = GTLRDriveQuery_FilesCreate.query(withObject: metaData, uploadParameters: uploadParameters)
            }****/
            
            
            // just create new each time for now
            query = GTLRDriveQuery_FilesCreate.query(withObject: metaData, uploadParameters: uploadParameters)

            query.fields = "id"
            
            //(GTLRServiceTicket *ticket,
            // GTLRDrive_File *file,
            //  NSError *error)
           
            self.service.executeQuery(query)
            { (ticket, file, error) -> Void  in
                
                print("ticket = \(ticket)")
                print("error = \(error)")
                
                if error == nil
                {
                    let theFile :GTLRDrive_File? = file as? GTLRDrive_File
                    if let theFile = theFile
                    {
                        print("File ID = \(theFile.identifier)")
                        self.showAlert(title: "Realm DB Saved", message: "Upload Success - Check your Google Drive To Verify")
                    }
                }
                else
                {
                    print("Error = \(error?.localizedDescription)")
                }
            }
        }
        else
        {
            print("Path not found")
            return
        }
    }
    
    func downloadFile()
    {
        // file.identifier for now
        if let id = fileR.identifier
        {
            let query :GTLRQuery = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
            service.executeQuery(query, delegate: self, didFinish: #selector(displayDownloadResultWithTicket(ticket:finishedWithObject:error:))
            )
            
        }
        else{
            showAlert(title: "oops....", message: "file.identifier is nil")
        }
    }

    @objc func displayDownloadResultWithTicket(ticket: GTLRServiceTicket,
                                       finishedWithObject result : GTLRDataObject,
                                       error : NSError?) {
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        showAlert(title: "OK", message: "download success")

        print("result.contentType = \(result.contentType)")
        print("\(result.data.base64EncodedString())")
        
    }
    
    // List up to 10 files in Drive
    func listFiles() {
        let query = GTLRDriveQuery_FilesList.query()
        query.orderBy = "createdTime desc"  //defaults to asc
        query.pageSize = 10
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:))
        )
    }
   
    // Process the response and display output
    @objc func displayResultWithTicket(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRDrive_FileList,
                                 error : NSError?) {
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        var text = "";
        if let files = result.files, !files.isEmpty {
            text += "Files:\n"
            
            // * first should be newest *
            
            for (i,file) in files.enumerated() {
                
                if i == 0
                {
                    fileR.identifier = file.identifier!
                    fileR.name = file.name!
                }
                text += "\(file.name!) (\(file.identifier!)"

                if let created = file.createdTime
                {
                    text += "\(created.date)"
                }
                
                if let modified = file.modifiedTime
                {
                    text += "\(modified.date)"
                }
            }
        } else {
            text += "No files found."
        }
        showAlert(title: "", message: text)
    }
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func uploadPressed(_ sender: UIButton)
    {
        if self.service.authorizer != nil
        {
            uploadFile()
        }
        else
        {
            showAlert(title: "Error Not Logged In", message: "Log in to Google Account First")
        }
    
    }
    
    @IBAction func downloadPressed(_ sender: UIButton)
    {
        if self.service.authorizer != nil
        {
            downloadFile()
        }
        else
        {
            showAlert(title: "Error Not Logged In", message: "Log in to Google Account First")
        }
        
    }
    
    @IBAction func googleSignInPressed(_ sender: UIButton)
    {
        GIDSignIn.sharedInstance().signInSilently()
    }
    
    
    @IBAction func listFilesPressed(_ sender: UIButton) {
        
        if self.service.authorizer != nil
        {
            listFiles()
        }
        else
        {
            showAlert(title: "Error Not Logged In", message: "Log in to Google Account First")
        }
        
    }
    
}

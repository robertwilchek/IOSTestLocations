import SwiftUI
import CodeScanner
import AVFoundation
import AlertToast
import UIKit
import MapKit

struct MainView: View {
    @ObservedObject var loginResponseHolder: LoginResponseHolder
    @State private var vehicles: [Vehicle] = []
    @State private var selectedMake: String?
    @State private var expandedMakes: Set<String> = []
    @State private var uniqueMakes: [String] = []
    @State private var uniqueLots: [String] = []
    @State private var uniqueStatuses: [String] = []
    @StateObject var baseURL = BaseURL()
    @State private var isLoading = true
    @State private var ChangeLots = false
    @State private var NewStock = false
    @State private var NewColor = false
    @State private var VehicleStatusChange = false
    @State private var GPSSettings = false
    @State private var addNotesInMain = false
    @State private var updateList = false
    @State private var addStatusInMain = false
    @State private var enteredNotes = ""
    @State private var enteredStatus = ""
    @State private var scanViewOpen = false
    @State private var selectedVehicleInContextMenu = ""
    @State private var scannedVehicles: [Vehicle] = []
    @State private var newVehicleScanned = false
    @State private var isVisible = false
    @State private var isVisibleForUnknown = false
    @State private var selectedLot = ""
    @State private var newStock = ""
    @State private var newColor = ""
    @State private var continueScan = false
    @State private var newLotSelected = false
    @State private var newStatusSelected = false
    @State private var newLotSelectedForUnknown = false
    @State private var newStockForUnknown = false
    @State private var newColorForUnknown = false
    @State private var vehicleLocation = ""
    @State private var isShowingScanner = false
    @State private var scannedCode = ""
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var scannedVehicleFile = ScannedVehicleFile()
    @State private var isShowingPopover = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var isTextFieldFocused: Bool = false // This should be FocusState, not State
    @FocusState private var isSearchFieldFocused: Bool
    //@State private var selectedOption: Option = .light
    //@State private var selectedSubOption: SubOption = .black
    //@AppStorage("selectedTheme") private var selectedTheme = ""
    //@AppStorage("selectedColors") private var selectedColors = ""
    @EnvironmentObject private var locationDataManager: LocationManager
    let loginResponse: LoginResponse?
    let speechSynthesizer = AVSpeechSynthesizer()
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    //@AppStorage("isDarkMode") private var isDarkMode = false
    var body: some View {
        VStack {
            ShowButtons()
            List {
                ForEach(uniqueMakes, id: \.self) { make in
                    Section(header: makeHeader(make)) {
                        if expandedMakes.contains(make) {
                            vehiclesForMake(make)
                        }
                    }
                }
            }
            Button(action: {
                // Action for Logout
                logout()
            }) {
                Text("LOGOUT")
                    .foregroundColor(.blue) // Styled as a link
            }
            
            .listStyle(InsetGroupedListStyle())
            .refreshable {
                // This closure is called when the user pulls to refresh
                if let response = loginResponse {
                    expandedMakes=[]
                    getSettings(loginResponse: response)
                    getVehicles(loginResponse: response,searchInText: searchText)
                }
            }
            .onAppear {
                if(vehicles.isEmpty || vehicles.count == 0){
                    if let response = loginResponse {
                        getSettings(loginResponse: response)
                        getVehicles(loginResponse: response,searchInText: searchText)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingScanner, onDismiss: {
            selectedLot=""
            newStock=""
            newColor=""

            if(selectedVehicleInContextMenu != "" && selectedVehicleInContextMenu != "BAD SCAN" && selectedVehicleInContextMenu != "SCAN AGAIN" && selectedVehicleInContextMenu != "READ_FAIL" &&  selectedVehicleInContextMenu != "Function evaluation timeout."){
                //let scannedveh = scannedVehicles.first(where: {$0.vin == selectedVehicleInContextMenu || $0.stockNo == selectedVehicleInContextMenu})
                let scannedveh=findVehicle(in: scannedVehicles, matching: selectedVehicleInContextMenu)
                if scannedveh == nil
                {
                    newVehicleScanned = true
                }
                else{
                    newVehicleScanned = false
                }
                if newVehicleScanned
                {
                    let handleLocation: (String?) -> Void = { locationString in
                        vehicleLocation = locationString ?? ""

                        var veh = findVehicle(in: vehicles, matching: selectedVehicleInContextMenu)
                        if var matchedVehicle = veh {
                            selectedVehicleInContextMenu = matchedVehicle.vin ?? ""

                            if let locationString, GPSSettings {
                                matchedVehicle.vehicleLocation = locationString
                                if let index = vehicles.firstIndex(where: { candidate in
                                    let sameVin = candidate.vin == matchedVehicle.vin && matchedVehicle.vin != nil
                                    let sameStock = candidate.stockNo == matchedVehicle.stockNo && matchedVehicle.stockNo != nil
                                    return sameVin || sameStock
                                }) {
                                    vehicles[index] = matchedVehicle
                                }
                            }

                            scannedVehicles.append(matchedVehicle)
                            if ChangeLots{
                                speakText(textToSpeak: "Select Lot")
                                selectedLot="[*NO CHANGE*]"
                                isVisible=true
                            }
                            else{
                                continueScan = true
                            }
                        }
                        else{
                            speakText(textToSpeak: "Unknown")
                            var scannedVehicle = Vehicle(
                                vin: selectedVehicleInContextMenu,
                                stockNo: "Unknown",
                                modelYear: "",
                                make: "",
                                model: "",
                                color: "",
                                licenseNo: "",
                                vType: "NEW",
                                body: "",
                                trimLevel: "",
                                miles: 0,
                                arrivalDate: "",
                                retailPrice: 0,
                                invoicePrice: 0,
                                lotLocation: "",
                                companyID: "",
                                stockInCo: "",
                                trans: "",
                                scannedDate: nil,
                                errorMessage: "",
                                location: "",
                                vehicleLocation: locationString
                            )
                            scannedVehicles.append(scannedVehicle)
                            if ChangeLots{
                                selectedLot="[*NO CHANGE*]"
                                isVisibleForUnknown=true
                            }
                            else{
                                if NewStock{
                                    newStockForUnknown=true
                                }
                                else{
                                    if NewColor{
                                        newColorForUnknown=true
                                    }
                                    else{
                                        continueScan=true
                                    }
                                }
                            }
                        }
                    }

                    if GPSSettings {
                        locationDataManager.currentLocationString { locationString in
                            handleLocation(locationString)
                        }
                    } else {
                        handleLocation(nil)
                    }
                }
                else{
                    speakText(textToSpeak: "Already Scanned")
                }
                scanViewOpen=true
            }
            else{
                speakText(textToSpeak: "Bad Scan")
                toastMessage = "Bad scan, try again!"
                showToast.toggle()
            }
        }) {
            CodeScannerView(codeTypes: [.qr,.aztec,.dataMatrix,.code128,.code93,.code39,.upce], completion: {result in
                selectedLot=""
                newStock=""
                newColor=""
                if case let .success(code) = result{
                    self.isShowingScanner=false
                    if code.type.rawValue == "org.iso.QRCode"{
                        let scannedResult=code.string.split(separator: ",")
                        self.scannedCode=String(scannedResult[0])
                        selectedVehicleInContextMenu=String(scannedResult[0])
                    }
                    else{
                        self.scannedCode=code.string
                        selectedVehicleInContextMenu = code.string
                    }
                }
            })
            Button("Cancel") {
                selectedLot=""
                newStock=""
                newColor=""
                isShowingScanner = false // Dismiss the camera view when the "Cancel" button is tapped
            }
            .navigationBarItems(trailing: Button("Cancel") {
                // Add a cancel button to dismiss the scanner view
                self.isShowingScanner = false
            })
        }
        .sheet(isPresented: $isVisible, onDismiss: {
            print("Dismissed")
            if(selectedLot == "[*NEW LOT*]"){
                newLotSelected = true
                selectedLot = ""
            }
            else{
                continueScan = true
            }
        }) {
            SelectLotView(isVisible: $isVisible, isVisibleForUnknown: $isVisibleForUnknown, selectedOption: $selectedLot, fullVehicles: vehicles, selectedVin: selectedVehicleInContextMenu, logingresponse: loginResponse, scannedVehicles: scannedVehicles, newVehicleScanned: newVehicleScanned, options: uniqueLots)
            Text("Selected Lot: \(selectedLot)")
        }
        .sheet(isPresented: $isVisibleForUnknown, onDismiss: {
            print("Dismissed")
            if(selectedLot == "[*NEW LOT*]"){
                newLotSelectedForUnknown = true
                selectedLot = ""
            }
            else{
                if NewStock{
                    newStockForUnknown=true
                }
                else{
                    if NewColor{
                        newColorForUnknown=true
                    }
                    else{
                        continueScan=true
                    }
                }
            }
        })
        {
            SelectLotView(isVisible: $isVisible, isVisibleForUnknown: $isVisibleForUnknown, selectedOption: $selectedLot, fullVehicles: vehicles, selectedVin: selectedVehicleInContextMenu, logingresponse: loginResponse, scannedVehicles: scannedVehicles, newVehicleScanned: newVehicleScanned, options: uniqueLots)
            Text("Selected Lot: \(selectedLot)")
        }
        .sheet(isPresented: $showSearch) {
            searchUI(searchText: $searchText, showSearch: $showSearch, loginResponse: loginResponse!)
        }
        .alert("New Lot", isPresented: $newLotSelected) {
            TextField("New Lot", text: $selectedLot)
            Button("OK", action: {
                continueScan = true
            })
        }
        .alert("New Lot", isPresented: $newLotSelectedForUnknown) {
            TextField("New Lot", text: $selectedLot)
            Button("OK", action: {
                if NewStock{
                    newStockForUnknown=true
                }
                else{
                    if NewColor{
                        newColorForUnknown=true
                    }
                    else{
                        continueScan=true
                    }
                }
            })
        }
        .alert("Stock No", isPresented: $newStockForUnknown) {
            TextField("Enter Stock No", text: $newStock)
            Button("OK", action: {
                if NewColor{
                    newColorForUnknown=true
                }
                else{
                    continueScan=true
                }
            })
        }
        .alert("Enter Color", isPresented: $newColorForUnknown) {
            TextField("Enter Color", text: $newColor)
            Button("OK", action: {
                continueScan=true
            })
        }
        .sheet(isPresented: $addStatusInMain, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if enteredStatus == "[*NEW STATUS*]" {
                    //newStatusSelected = true
                    enteredStatus = ""
                    showAlertWithTextFieldForStatus()
                }else if enteredStatus == "[*BLANK STATUS*]" {
                    let selectedVehicle=findVehicle(in: vehicles, matching: selectedVehicleInContextMenu)
                    AddStatus(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", status: "")
                }else if enteredStatus != "" {
                    //let selectedVehicle = vehicles.first(where: { $0.vin == selectedVehicleInContextMenu })
                    let selectedVehicle=findVehicle(in: vehicles, matching: selectedVehicleInContextMenu)
                    AddStatus(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", status: enteredStatus)
                }
            }
        }) {
            SelectStatusView(addStatus: $addStatusInMain, selectedOption: $enteredStatus, options: uniqueStatuses)
            Text("Selected Status: \(enteredStatus)")
        }
        .background(
            NavigationLink(
                destination: ScanView(fullVehicles: vehicles, selectedVin: selectedVehicleInContextMenu, logingresponse: loginResponse, scannedVehicles: $scannedVehicles, newVehicleScanned: newVehicleScanned, vehicleLot: selectedLot,vehicleLocation: vehicleLocation,vehicleStatusChange: VehicleStatusChange,GPSSettings: GPSSettings,ChangeLots: ChangeLots,stockNo: newStock,color: newColor,uniqueStatuses: uniqueStatuses, uniqueLots: uniqueLots,NewStock: NewStock,NewColor: NewColor),
                isActive: $continueScan
            ){}
                .padding()
                .hidden()
        )
        .toast(isPresenting: $showToast){
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }
    }
    
    private var themeButton: some View {
        Button(action: {
            isShowingPopover.toggle()
        }) {
            Image(systemName: "slider.horizontal.3")
        }
    }
    
    private var cameraButton: some View {
        Button(action: {
            isShowingScanner=true
        }) {
            Image(systemName: "camera")
        }
    }
    func findVehicle(in vehicles: [Vehicle], matching key: String) -> Vehicle? {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        for vehicle in vehicles {
            let normalizedVin = vehicle.vin?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let normalizedStockNo = vehicle.stockNo?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            
            print("Checking VIN: \(normalizedVin), StockNo: \(normalizedStockNo) against \(normalizedKey)")
            
            if normalizedVin == normalizedKey || normalizedStockNo == normalizedKey {
                print("Match found: \(vehicle)")
                return vehicle
            }
        }
        
        print("No match found for key: \(normalizedKey)")
        return nil
    }


    private func makeHeader(_ make: String) -> some View {
        HStack {
            Text(make)
                .font(.headline)
                .onTapGesture {
                    toggleExpandMake(make)
                }
        }
    }
    
    func restartApp(){
        if let response = loginResponse {
            expandedMakes=[]
            getSettings(loginResponse: response)
            getVehicles(loginResponse: response,searchInText: searchText)
        }
    }

    private func vehiclesForMake(_ make: String) -> some View {
        ForEach(vehicles.filter { $0.make == make }, id: \.id) { vehicle in
            vehicleDetails(vehicle)
                .contextMenu{
                    Button {
                        restartApp()
                    } label: {
                        Label("Update/Refresh Vehicle List", systemImage: "")
                    }
                    Button {
                        selectedVehicleInContextMenu = vehicle.vin ?? ""
                        //let scannedveh = scannedVehicles.first(where: {$0.vin == selectedVehicleInContextMenu})
                        let scannedveh=findVehicle(in: scannedVehicles, matching: selectedVehicleInContextMenu)
                        if scannedveh == nil{
                            newVehicleScanned = true
                        }
                        else{
                            newVehicleScanned = false
                        }
                        if newVehicleScanned{
                            let handleLocation: (String?) -> Void = { locationString in
                                vehicleLocation = locationString ?? ""
                                if var selectedVehicle = findVehicle(in: vehicles, matching: selectedVehicleInContextMenu) {
                                    if let locationString, GPSSettings {
                                        selectedVehicle.vehicleLocation = locationString
                                        if let index = vehicles.firstIndex(where: { candidate in
                                            let sameVin = candidate.vin == selectedVehicle.vin && selectedVehicle.vin != nil
                                            let sameStock = candidate.stockNo == selectedVehicle.stockNo && selectedVehicle.stockNo != nil
                                            return sameVin || sameStock
                                        }) {
                                            vehicles[index] = selectedVehicle
                                        }
                                    }

                                    scannedVehicles.append(selectedVehicle)
                                }

                                if ChangeLots{
                                    speakText(textToSpeak: "Select Lot")
                                    selectedLot="[*NO CHANGE*]"
                                    isVisible=true
                                }
                                else{
                                    continueScan = true
                                }
                            }

                            if GPSSettings {
                                locationDataManager.currentLocationString { locationString in
                                    handleLocation(locationString)
                                }
                            } else {
                                handleLocation(nil)
                            }
                        }
                        else{
                            speakText(textToSpeak: "Already Scanned")
                        }
                        scanViewOpen=true
                    } label: {
                        Label("Set Vehicle as Scanned", systemImage: "")
                    }
                    Button {
                        speakText(textToSpeak: "Enter Notes")
                        selectedVehicleInContextMenu = vehicle.vin ?? ""
                        addNotesInMain = true
                        showAlertWithTextFieldForNotes()
                    } label: {
                        Label("Add Notes", systemImage: "")
                    }
                    if VehicleStatusChange{
                        Button {
                            speakText(textToSpeak: "Enter Status")
                            selectedVehicleInContextMenu = vehicle.vin ?? ""
                            addStatusInMain=true
                        } label: {
                            Label("Vehicle Status", systemImage: "")
                        }
                    }
                    Button {
                        if(vehicle.vehicleLocation != nil && vehicle.vehicleLocation != "" && vehicle.vehicleLocation != "\"\""){
                            var vehLoc: String = ""

                            if let vehicleLocation = vehicle.vehicleLocation, vehicleLocation.contains("\"") {
                                vehLoc = removeFirstAndLastCharacter(vehicleLocation)
                            } else if let vehicleLocation = vehicle.vehicleLocation {
                                vehLoc = vehicleLocation
                            }
                            let coord=vehLoc.split(separator: "_")
                            let latitude=coord[0]
                            let longitude=coord[1]
                            openMaps(latitude: latitude.description.toDouble() ?? 0.0, longitude: longitude.description.toDouble() ?? 0.0)
                        }
                        else{
                            toastMessage="Last Known Location not found"
                            showToast.toggle()
                        }
                    } label: {
                        Label("Locate Vehicle", systemImage: "")
                    }
                }
        }
    }
    
    private func vehicleDetails(_ vehicle: Vehicle) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack {
                if(vehicle.vehicleLocation != nil && vehicle.vehicleLocation != "" && vehicle.vehicleLocation != "\"\"")
                {
                    Image("GreenPin" )
                        .resizable()
                        .frame(width: 50,height:50)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            var vehLoc: String = ""
                            
                            if let vehicleLocation = vehicle.vehicleLocation, vehicleLocation.contains("\"") {
                                vehLoc = removeFirstAndLastCharacter(vehicleLocation)
                            } else if let vehicleLocation = vehicle.vehicleLocation {
                                vehLoc = vehicleLocation
                            }
                            let coord=vehLoc.split(separator: "_")
                            let latitude=coord[0]
                            let longitude=coord[1]
                            openMaps(latitude: latitude.description.toDouble() ?? 0.0, longitude: longitude.description.toDouble() ?? 0.0)
                        }
                }
                else
                {
                    Image("YellowPin" )
                        .resizable()
                        .frame(width: 50,height:50)
                        .foregroundColor(.blue)
                }
                
            }
            .font(.title) // You can adjust the icon size here
            .padding(.trailing, 8) // Adjust the spacing between icons and details
            
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Year: \(vehicle.modelYear ?? "")")
                Text("Model: \(vehicle.model ?? "")")
                Text("Color: \(vehicle.color ?? "")")
                Text("Stock: \(vehicle.stockNo ?? "")")
                Text("VIN: \(vehicle.vin ?? "")")
                    .padding(.vertical, 4)
            }
        }
        
    }
    
    func showAlertWithTextFieldForStatus() {
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
        let alertController = UIAlertController(title: "Vehicle Status", message: nil, preferredStyle: .alert)
        
        // Add a text field to the alert
        alertController.addTextField { textField in
            textField.placeholder = "Enter new status"
        }
        
        // Cancel action for the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            newStatusSelected = false
        }
        
        // OK action for the alert
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let textField = alertController.textFields?.first {
                enteredStatus = textField.text ?? ""
                
                // Add status logic
                //let selectedVehicle = vehicles.first(where: { $0.vin == selectedVehicleInContextMenu })
                let selectedVehicle=findVehicle(in: vehicles, matching: selectedVehicleInContextMenu)
                AddStatus(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", status: enteredStatus)
                
                newStatusSelected = false
            }
        }
        
        // Add actions to the alert
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        // Present the alert
        rootVC.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWithTextFieldForNotes() {
         guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
             return
         }

         let alertController = UIAlertController(title: "Add Notes", message: nil, preferredStyle: .alert)
         
         // Add TextField to the alert
         alertController.addTextField { textField in
             textField.placeholder = "Add Notes"
         }

         // Cancel action
         let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
             addNotesInMain = false
         }

         // OK action
         let okAction = UIAlertAction(title: "OK", style: .default) { _ in
             if let textField = alertController.textFields?.first {
                 enteredNotes = textField.text ?? ""
                 
                 // Handle note addition
                 //if let selectedVehicle = vehicles.first(where: { $0.vin == selectedVehicleInContextMenu }) {
                 if let selectedVehicle = findVehicle(in: vehicles, matching: selectedVehicleInContextMenu) {
                     AddNotes(stock: selectedVehicle.stockNo ?? "", vin: selectedVehicle.vin ?? "", notes: enteredNotes)
                 }
                 
                 addNotesInMain = false
             }
         }

         // Add actions to the alert
         alertController.addAction(cancelAction)
         alertController.addAction(okAction)

         // Present the alert
         rootVC.present(alertController, animated: true, completion: nil)
     }

    private func openMaps(latitude: Double, longitude: Double) {
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        
        let options: [String: Any] = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinates),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001))
        ]
        
        mapItem.openInMaps(launchOptions: options)
    }

    
    private func AddNotes(stock: String, vin: String, notes: String){
        enteredNotes = ""
        let queryItems = [URLQueryItem(name: "Token", value: loginResponse?.token ?? ""),
                          URLQueryItem(name: "dealerid", value: String(loginResponse?.dealerId ?? "0")),
                          URLQueryItem(name: "strStockNo", value: stock),
                          URLQueryItem(name: "strVIN", value: vin),
                          URLQueryItem(name: "Username", value: loginResponse?.username ?? ""),
                          URLQueryItem(name: "notes", value: notes)]
        
        let url = URL(string: baseURL.URL+"VehWizAPI/AddNotes")!
        let newURL = url.appending(queryItems: queryItems)
        // Create the request object
        var request = URLRequest(url: newURL)
        
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.setValue("Bearer \(loginResponse.token)", forHTTPHeaderField: "Authorization")
        
        // Perform the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Handle the error
                print("Error: \(error)")
                return
            }
            
            // Check the response status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle the non-successful response
                print("Invalid response")
                return
            }
            print("debug")
            // Parse the JSON data into an array of Vehicle objects
            if let data = data {
                let res = String(data: data, encoding: .utf8)
                if(res=="Success"){
                    toastMessage="Success!"
                    showToast.toggle()
                }
                else{
                    toastMessage="Failed!"
                    showToast.toggle()
                }
            }
        }.resume()
    }
    
    private func AddStatus(stock: String, vin: String, status: String){
        enteredStatus = ""
        let queryItems = [URLQueryItem(name: "Token", value: loginResponse?.token ?? ""),
                          URLQueryItem(name: "dealerid", value: String(loginResponse?.dealerId ?? "0")),
                          URLQueryItem(name: "strStockNo", value: stock),
                          URLQueryItem(name: "strVIN", value: vin),
                          URLQueryItem(name: "Username", value: loginResponse?.username ?? ""),
                          URLQueryItem(name: "vehiclestatus", value: status)]
        
        let url = URL(string: baseURL.URL+"VehWizAPI/AddVehicleStatus")!
        let newURL = url.appending(queryItems: queryItems)
        // Create the request object
        var request = URLRequest(url: newURL)
        
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.setValue("Bearer \(loginResponse.token)", forHTTPHeaderField: "Authorization")
        
        // Perform the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Handle the error
                print("Error: \(error)")
                return
            }
            
            // Check the response status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle the non-successful response
                print("Invalid response")
                return
            }
            print("debug")
            // Parse the JSON data into an array of Vehicle objects
            if let data = data {
                let res = String(data: data, encoding: .utf8)
                if(res=="Success"){
                    toastMessage="Success!"
                    showToast.toggle()
                }
                else{
                    toastMessage="Failed!"
                    showToast.toggle()
                }
            }
        }.resume()
    }
    
    private func toggleExpandMake(_ make: String) {
        if expandedMakes.contains(make){
            expandedMakes.remove(make)
        } else {
            expandedMakes.insert(make)
        }
    }
    private func getSettings(loginResponse: LoginResponse){
        let url = URL(string: baseURL.URL+"VehWizAPI/GetScannerSettings")!
        // Create the request object
        var request = URLRequest(url: url)
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(loginResponse)
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON data: \(error)")
            return
        }
        
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.setValue("Bearer \(loginResponse.token)", forHTTPHeaderField: "Authorization")
        
        // Perform the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Handle the error
                print("Error: \(error)")
                return
            }
            
            // Check the response status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle the non-successful response
                print("Invalid response")
                return
            }
            print("debug")
            // Parse the JSON data into an array of Vehicle objects
            if let data = data {
                do {
                    let aa = String(data: data, encoding: .utf8)
                    let bb = aa?.dropLast(1).dropFirst(1)
                    let res = bb?.split(separator: ";")
                    ChangeLots = NSString(string: res![0].description).boolValue
                    NewStock = NSString(string: res![1].description).boolValue
                    NewColor = NSString(string: res![2].description).boolValue
                    VehicleStatusChange = NSString(string: res![3].description).boolValue
                    GPSSettings = NSString(string: res![4].description).boolValue
                    
                    if VehicleStatusChange{
                        getUniqueStatuses(loginResponse: loginResponse)
                    }
                } catch {
                    // Handle the JSON decoding error
                    print("JSON decoding error: \(error)")
                }
            }
        }.resume()
    }
    private func getUniqueStatuses(loginResponse: LoginResponse) {
        let url = URL(string: baseURL.URL + "VehWizAPI/GetUniqueStatuses")!

        // Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Uncomment the line below if your API requires authentication
        // request.setValue("Bearer \(loginResponse.token)", forHTTPHeaderField: "Authorization")

        // Encode the LoginResponse as JSON and set it as the HTTP body
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(loginResponse)
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON data: \(error)")
            return
        }

        // Perform the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Handle the network error
                print("Network Error: \(error)")
                isLoading = false
                return
            }

            // Check the response status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle non-successful response
                print("Invalid response")
                isLoading = false
                return
            }

            if let data = data {
                uniqueStatuses = []
                uniqueStatuses.append("Select a Status")
                uniqueStatuses.append("[*NEW STATUS*]")
                uniqueStatuses.append("[*BLANK STATUS*]")
                if(data.count>0){
                    do {
                        // Decode the JSON response into an array of strings
                        let resp = try JSONDecoder().decode([String?].self, from: data)
                        uniqueStatuses.append(contentsOf: resp.compactMap { $0 })
                        // Use uniqueStatuses as needed in your app
                    } catch {
                        // Handle the JSON decoding error
                        print("JSON decoding error: \(error)")
                    }
                }
            }
        }.resume()
    }
    @ViewBuilder
    private func ShowButtons() -> some View {
        // Top buttons
        HStack {
            // Scan List Button
            Button(action: {
                if !continueScan {
                    //selectedVehicleInContextMenu = ""
                    continueScan  = true
                }
            }) {
                Text("SCAN")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            // Spacer to position Search button to the right of Scan List
            Spacer(minLength: 10)

            // Search Button
            Button(action: {
                showSearch.toggle()
            }) {
                Text("SEARCH")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            // Spacer to push Logout to the far right
            Spacer()
            cameraButton
            /*Spacer()
            // Logout Link
            Button(action: {
                // Action for Logout
                logout()
            }) {
                Text("Logout")
                    .foregroundColor(.blue) // Styled as a link
            }*/
        }
        .padding()

    }

    func logout() {
        loginResponseHolder.loginResponse = nil
    }
    private func searchUI(searchText: Binding<String>, showSearch: Binding<Bool>, loginResponse: LoginResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Instructional Text
            Text("Enter in partial information for matching stock, VIN, body, or model information.")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.horizontal)

            // TextField with default focus
            TextField("Enter search terms", text: searchText)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($isSearchFieldFocused) // Set focus to TextField
                .onAppear {
                    isSearchFieldFocused = true // Set the focus when the view appears
                }
            
            // Buttons placed under the TextField
            HStack {
                Spacer()
                Button(action: {
                    // Handle search action
                    getVehicles(loginResponse: loginResponse, searchInText: searchText.wrappedValue)
                    showSearch.wrappedValue = false // Hide search box after search
                }) {
                    Text("Search")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.trailing, 10)

                Button(action: {
                    // Cancel search action
                    searchText.wrappedValue = ""
                    showSearch.wrappedValue = false
                }) {
                    Text("Cancel")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    private func getVehicles(loginResponse: LoginResponse,searchInText: String) {
        let url = URL(string: baseURL.URL+"VehWizAPI/GetVehicles")!
        // Create the request object
        var request = URLRequest(url: url)
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(loginResponse)
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON data: \(error)")
            return
        }
        
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //request.setValue("Bearer \(loginResponse.token)", forHTTPHeaderField: "Authorization")
        
        // Perform the API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Handle the error
                print("Error: \(error)")
                isLoading = false
                return
            }
            
            // Check the response status code
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle the non-successful response
                print("Invalid response")
                isLoading = false
                return
            }

            // Parse the JSON data into an array of Vehicle objects
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print(jsonString.prefix(2000))
                        let filename = getDocumentsDirectory().appendingPathComponent("output.txt")
                        
                        do {
                            try jsonString.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                        } catch {
                            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                            print("WriteFile: \(error)")

                        }
                    }
                    let vehicleList = try decoder.decode([Vehicle].self, from: data)
                    let filteredVehicleList = filterVehicles(vehicleList, with: searchInText)
                    let lots = Set(filteredVehicleList.compactMap { $0.lotLocation })
                    uniqueLots = []
                    uniqueMakes = []
                    uniqueLots.append("[*NO CHANGE*]")
                    uniqueLots.append("[*NEW LOT*]")
                    uniqueLots.append(contentsOf: lots)
                    for veh in filteredVehicleList {
                        if uniqueMakes.contains(veh.make ?? "") == false {
                            uniqueMakes.append(veh.make ?? "")
                        }
                    }
                    // Update the @State property to trigger a view update
                    DispatchQueue.main.async {
                        vehicles = filteredVehicleList
                    }
                    isLoading = false
                } catch {
                    // Handle the JSON decoding error
                    print("JSON decoding error: \(error)")
                    isLoading = false
                }
            }
        }.resume()
    }
    private func filterVehicles(_ vehicles: [Vehicle], with searchInText: String) -> [Vehicle] {
        guard !searchText.isEmpty else {
            return vehicles
        }
        
        let lowercasedSearchText = searchInText.lowercased()
        
        return vehicles.filter { vehicle in
            return (vehicle.vin?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.stockNo?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.modelYear?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.make?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.model?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.color?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.licenseNo?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.vType?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.body?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.trimLevel?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.trans?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.location?.lowercased().contains(lowercasedSearchText) ?? false) ||
                   (vehicle.lotLocation?.lowercased().contains(lowercasedSearchText) ?? false)
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func speakText(textToSpeak: String) {
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        speechSynthesizer.speak(utterance)
    }
    func removeFirstAndLastCharacter(_ str: String) -> String {
        let start = str.index(str.startIndex, offsetBy: 1)
        let end = str.index(str.endIndex, offsetBy: -1)
        return String(str[start..<end])
    }
}
extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue 
    }
}

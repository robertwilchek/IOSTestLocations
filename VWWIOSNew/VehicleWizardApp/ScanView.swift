//
//  ScanView.swift
//  VehicleWizardApp
//
//  Created by Sandeep kumar Turimella on 23/06/23.
//

import SwiftUI
import AVFoundation
import CodeScanner

struct ScanView: View {
    //@State private var baseURL = "http://40.117.173.178/"
    @StateObject var baseURL = BaseURL()
    @State private var isLoading = true
    @State private var toastMessage = false
    @State private var finalLotLocation = ""
    @State private var isShowingScanner = false
    @State private var addNotes = false
    @State private var selectedVehicleInContextMenu = ""
    @State private var addStatus = false
    @State private var showToast = false
    @State private var message = ""
    @State private var enteredNotes = ""
    @State private var enteredStatus = ""
    @State private var isVisible = false
    @State private var isVisibleForUnknown = false
    @State private var continueScan = false
    @State private var scannedCode = ""
    @State private var newStatusSelected = false
    @State private var selectedLot = ""
    @State private var newStock = ""
    @State private var newColor = ""
    @State private var newLotSelected = false
    @State private var newStockForUnknown = false
    @State private var newColorForUnknown = false
    @State private var newLotSelectedForUnknown = false
    @State private var newScannedVehicle = Vehicle()
    @EnvironmentObject private var locationDataManager: LocationManager
    let fullVehicles: [Vehicle]
    let selectedVin: String?
    let logingresponse: LoginResponse?
    //var scannedVehicles: [Vehicle]
    @Binding var scannedVehicles: [Vehicle]
    let newVehicleScanned: Bool
    let vehicleLot: String
    let vehicleLocation: String
    let speechSynthesizer = AVSpeechSynthesizer()
    let vehicleStatusChange: Bool
    let GPSSettings: Bool
    let ChangeLots: Bool
    var stockNo: String
    let color: String
    let uniqueStatuses: [String]
    let uniqueLots: [String]
    let NewStock: Bool
    let NewColor: Bool
    var body: some View {
        VStack{
            List(scannedVehicles, id: \.vin) { veh in
                HStack{
                    Text("")
                        .navigationBarItems(trailing: cameraButton)
                    let textToDisplay = (veh.stockNo ?? "")+"\n"+(veh.modelYear ?? "")+"\t"+(veh.make ?? "")+"\t"+(veh.model ?? "")
                    Text(textToDisplay)
                    Spacer()
                    if isLoading{
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                    }
                }
                .padding()

                .alert("Add Notes", isPresented: $addNotes) {
                    TextField("Add Notes", text: $enteredNotes)
                    Button("Cancel",action: {
                        addNotes=false
                    })
                    Button("OK", action: {
                        addNotes=false
                        let selectedVehicle = findVehicle(in: scannedVehicles, matching: selectedVehicleInContextMenu)
                        AddNotes(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", notes: enteredNotes)
                    })
                }
                .alert("New Lot", isPresented: $newLotSelected) {
                    TextField("New Lot", text: $selectedLot)
                    Button("OK", action: {
                        //continueScan = true
                        finalLotLocation=selectedLot
                        SendToDataBase(vehicleToUpdate: newScannedVehicle)
                        //scannedVehicles = scannedVehicles + [newScannedVehicle]
                        addVehicleIfUnique(to: &scannedVehicles, newVehicle: newScannedVehicle)
                    })
                }
                .alert("New Lot", isPresented: $newLotSelectedForUnknown) {
                    TextField("New Lot", text: $selectedLot)
                    Button("OK", action: {
                        finalLotLocation=selectedLot
                        if NewStock{
                            newStockForUnknown=true
                        }
                        else{
                            if NewColor{
                                newColorForUnknown=true
                            }
                            else{
                                SendToDataBase(vehicleToUpdate: newScannedVehicle)
                                //scannedVehicles = scannedVehicles + [newScannedVehicle]
                                addVehicleIfUnique(to: &scannedVehicles, newVehicle: newScannedVehicle)

                            }
                        }
                    })
                }
                /*.alert("Vehicle Status", isPresented: $addStatus) {
                 TextField("Vehicle Status", text: $enteredStatus)
                 Button("Cancel",action: {})
                 Button("OK", action: {
                 let selectedVehicle = scannedVehicles.first(where: { $0.vin == selectedVehicleInContextMenu})
                 AddStatus(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", status: enteredStatus)
                 })
                 }*/
                /*.sheet(isPresented: $addStatus, onDismiss: {
                    let aa = enteredStatus
                    if(enteredStatus == "[*NEW STATUS*]"){
                        newStatusSelected = true
                        enteredStatus = ""
                    }
                    else{
                        let selectedVehicle = findVehicle(in: scannedVehicles, matching: selectedVehicleInContextMenu)
                        AddStatus(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", status: enteredStatus)
                    }
                }) {
                    SelectStatusView(addStatus: $addStatus, selectedOption: $enteredStatus, options: uniqueStatuses)
                    Text("Selected Status: \(enteredStatus)")
                }*/
                .alert("Vehicle Status", isPresented: $newStatusSelected) {
                    TextField("Vehicle Status", text: $enteredStatus)
                    Button("Cancel",action: {})
                    Button("OK", action: {
                        let selectedVehicle = findVehicle(in: scannedVehicles, matching: selectedVehicleInContextMenu)
                        AddStatus(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", status: enteredStatus)
                    })
                }
                .alert("Stock No", isPresented: $newStockForUnknown) {
                    TextField("Enter Stock No", text: $newStock)
                    Button("OK", action: {
                        newScannedVehicle.stockNo=newStock
                        if NewColor{
                            newColorForUnknown=true
                        }
                        else{
                            //continueScan=true
                            SendToDataBase(vehicleToUpdate: newScannedVehicle)
                            //scannedVehicles = scannedVehicles + [newScannedVehicle]
                            addVehicleIfUnique(to: &scannedVehicles, newVehicle: newScannedVehicle)
                        }
                    })
                }
                .alert("Enter Color", isPresented: $newColorForUnknown) {
                    TextField("Enter Color", text: $newColor)
                    Button("OK", action: {
                        //continueScan=true
                        newScannedVehicle.color=newColor
                        SendToDataBase(vehicleToUpdate: newScannedVehicle)
                        //scannedVehicles = scannedVehicles + [newScannedVehicle]
                        addVehicleIfUnique(to: &scannedVehicles, newVehicle: newScannedVehicle)
                    })
                }
                .onAppear{
                    if selectedLot.isEmpty {
                        selectedLot = vehicleLot
                    }
                    if newVehicleScanned && veh.vin == selectedVin
                    {
                        let selectedVin = selectedVin?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        //var selectedVehicle = fullVehicles.first(where: { $0.vin == selectedVin})
                        var selectedVehicle = findVehicleByVin(in: fullVehicles, matchingVin: selectedVin)
                        if let vehicle = selectedVehicle{
                            if(vehicleLot == "[*NO CHANGE*]"){
                                finalLotLocation = vehicle.lotLocation ?? ""
                            }
                            else{
                                finalLotLocation = vehicleLot
                            }
                            let resp = SendToDataBase(vehicleToUpdate: vehicle)
                        }
                        else{
                            selectedVehicle=findVehicleByVin(in: scannedVehicles, matchingVin: selectedVin)
                            if(stockNo==nil||stockNo==""){
                                selectedVehicle?.stockNo="Unknown"
                            }
                            else{
                                selectedVehicle?.stockNo=stockNo
                            }
                            selectedVehicle?.color=color
                            if(vehicleLot == "[*NO CHANGE*]"){
                                finalLotLocation = selectedVehicle?.lotLocation ?? ""
                            }
                            else{
                                finalLotLocation = vehicleLot
                            }
                            if let veh = selectedVehicle{
                                let resp=SendToDataBase(vehicleToUpdate: veh)
                            }
                        }
                    }
                }
                .contextMenu(ContextMenu(menuItems: {
                    Button {
                        speakText(textToSpeak: "Enter Notes")
                        selectedVehicleInContextMenu = veh.vin ?? ""
                        addNotes = true
                    } label: {
                        Label("Add Notes", systemImage: "")
                    }
                    if vehicleStatusChange{
                        Button {
                            speakText(textToSpeak: "Enter Status")
                            selectedVehicleInContextMenu = veh.vin ?? ""
                            addStatus=true
                        } label: {
                            Label("Vehicle Status", systemImage: "")
                        }
                    }
                    Button {
                        if(veh.vehicleLocation != nil && veh.vehicleLocation != ""){
                            /*let coord=veh.vehicleLocation?.split(separator: "_")
                             let latitude=coord?[0]
                             let longitude=coord?[1]*/
                            
                            var vehLoc: String = ""
                            
                            if let vehicleLocation = veh.vehicleLocation, vehicleLocation.contains("\"") {
                                vehLoc = removeFirstAndLastCharacter(vehicleLocation)
                            } else if let vehicleLocation = veh.vehicleLocation {
                                vehLoc = vehicleLocation
                            }
                            let coord=vehLoc.split(separator: "_")
                            let latitude=coord[0]
                            let longitude=coord[1]
                            openMaps(latitude: latitude.description.toDouble() ?? 0.0, longitude: longitude.description.toDouble() ?? 0.0)
                        }
                        else{
                            message="Last Known Location not found"
                            showToast.toggle()
                        }
                    } label: {
                        Label("Locate Vehicle", systemImage: "")
                    }
                }))
            }
            .sheet(isPresented: $isShowingScanner, onDismiss: {
                if(selectedVehicleInContextMenu != "" && selectedVehicleInContextMenu != "BAD SCAN" && selectedVehicleInContextMenu != "SCAN AGAIN" && selectedVehicleInContextMenu != "READ_FAIL" &&  selectedVehicleInContextMenu != "Function evaluation timeout."){
                    let scannedveh = findVehicle(in: scannedVehicles, matching: selectedVehicleInContextMenu)
                    var newVehicle=false
                    if scannedveh == nil{
                        newVehicle = true
                    }
                    else{
                        newVehicle = false
                    }
                    if newVehicle{
                        //var veh = fullVehicles.first(where: {$0.vin == selectedVehicleInContextMenu || $0.stockNo == selectedVehicleInContextMenu})
                        var veh = findVehicle(in: fullVehicles, matching: selectedVehicleInContextMenu)

                        let handleLocation: (String?) -> Void = { locationString in
                            let resolvedLocation = locationString ?? vehicleLocation

                            if var sveh = veh {
                                if let locationString, GPSSettings {
                                    sveh.vehicleLocation = locationString
                                } else if GPSSettings {
                                    sveh.vehicleLocation = resolvedLocation
                                }
                                newScannedVehicle = sveh
                                if ChangeLots{
                                    speakText(textToSpeak: "Select Lot")
                                    isVisible=true
                                }
                                else{
                                    SendToDataBase(vehicleToUpdate: newScannedVehicle)
                                    addVehicleIfUnique(to: &scannedVehicles, newVehicle: newScannedVehicle)
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
                                    vehicleLocation: resolvedLocation
                                )

                                newScannedVehicle = scannedVehicle
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
                                            SendToDataBase(vehicleToUpdate: newScannedVehicle)
                                            addVehicleIfUnique(to: &scannedVehicles, newVehicle: newScannedVehicle)
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
                }
                else{
                    speakText(textToSpeak: "Bad Scan")
                    message = "Bad scan, try again!"
                    showToast.toggle()
                }
            }) {
                CodeScannerView(codeTypes: [.qr,.aztec,.dataMatrix,.code128,.code93,.code39,.upce], completion: {result in
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
                    isShowingScanner = false // Dismiss the camera view when the "Cancel" button is tapped
                }
                .navigationBarItems(trailing: Button("Cancel") {
                    // Add a cancel button to dismiss the scanner view
                    self.isShowingScanner = false
                })
            }
        }
        
        if isVisible {
            
            VStack {
                Text("Select Lot")
                    .font(.title)
                    .padding()
                
                Picker("Lots", selection: $selectedLot) {
                    ForEach(uniqueLots, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                Button("Submit"){
                    if isVisible{
                        isVisible=false
                        handleSelection()
                    }
                }
                .padding()
            }
            .frame(width: 300, height: 200)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        
        if isVisibleForUnknown {
            
            VStack {
                Text("Select Lot")
                    .font(.title)
                    .padding()
                
                Picker("Lots", selection: $selectedLot) {
                    ForEach(uniqueLots, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                Button("Submit"){
                    if isVisibleForUnknown{
                        isVisibleForUnknown=false
                        handleSelectionForUnknown()
                    }
                }
                .padding()
            }
            .frame(width: 300, height: 200)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        
        if addStatus{
            VStack {
                Text("Select Status")
                    .font(.title)
                    .padding()
                
                Picker("Status", selection: $enteredStatus) {
                    ForEach(uniqueStatuses, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                Button("Submit"){
                    if addStatus{
                        addStatus=false
                        let aa = enteredStatus
                        if(enteredStatus == "[*NEW STATUS*]"){
                            newStatusSelected = true
                            enteredStatus = ""
                        }
                        else if enteredStatus=="[*BLANK STATUS*]"{
                            let selectedVehicle = findVehicle(in: scannedVehicles, matching: selectedVehicleInContextMenu)
                            AddStatus(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", status: "")
                        }
                        else{
                            let selectedVehicle = findVehicle(in: scannedVehicles, matching: selectedVehicleInContextMenu)
                            AddStatus(stock: selectedVehicle?.stockNo ?? "", vin: selectedVehicle?.vin ?? "", status: enteredStatus)
                        }
                    }
                }
                .padding()
            }
            .frame(width: 300, height: 200)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
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
    func addVehicleIfUnique(to vehicles: inout [Vehicle], newVehicle: Vehicle) {
        guard !vehicles.contains(where: { $0.vin == newVehicle.vin }) else {
            return
        }
        vehicles.append(newVehicle)
    }
    func findVehicleByVin(in vehicles: [Vehicle], matchingVin: String?) -> Vehicle? {
        guard let vinToMatch = matchingVin?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            print("Invalid or nil VIN to match")
            return nil
        }
        
        for vehicle in vehicles {
            guard let vehicleVin = vehicle.vin?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                print("Skipping vehicle with nil VIN")
                continue
            }
            
            print("Checking vehicle VIN: \(vehicleVin) against selected VIN: \(vinToMatch)")
            
            if vehicleVin == vinToMatch {
                print("Match found! Vehicle: \(vehicle)")
                return vehicle
            }
        }
        
        print("No match found for VIN: \(vinToMatch)")
        return nil
    }

    private func handleSelection() {
        print("Dismissed")
        if(selectedLot == "[*NEW LOT*]"){
            newLotSelected = true
            selectedLot = ""
        }
        else{
            //continueScan = true
            if(selectedLot=="[*NO CHANGE*]"){
                finalLotLocation=newScannedVehicle.lotLocation ?? ""
            }
            else{
                finalLotLocation=selectedLot
            }
            SendToDataBase(vehicleToUpdate: newScannedVehicle)
            //scannedVehicles = scannedVehicles + [newScannedVehicle]
            addVehicleIfUnique(to: &scannedVehicles, newVehicle: newScannedVehicle)
        }
    }
    private func handleSelectionForUnknown() {
        print("Dismissed")
        if(selectedLot == "[*NEW LOT*]"){
            newLotSelectedForUnknown = true
            selectedLot = ""
        }
        else{
            if(selectedLot == "[*NO CHANGE*]"){
                finalLotLocation = newScannedVehicle.lotLocation ?? ""
            }
            else{
                finalLotLocation = selectedLot
            }
            if NewStock{
                newStockForUnknown=true
            }
            else{
                if NewColor{
                    newColorForUnknown=true
                }
                else{
                    SendToDataBase(vehicleToUpdate: newScannedVehicle)
                    //scannedVehicles = scannedVehicles + [newScannedVehicle]
                    addVehicleIfUnique(to: &scannedVehicles, newVehicle: newScannedVehicle)
                }
            }
        }
    }
    private func AddNotes(stock: String, vin: String, notes: String){
        enteredNotes = ""
        let queryItems = [URLQueryItem(name: "Token", value: logingresponse?.token ?? ""),
                          URLQueryItem(name: "dealerid", value: String(logingresponse?.dealerId ?? "0")),
                          URLQueryItem(name: "strStockNo", value: stock),
                          URLQueryItem(name: "strVIN", value: vin),
                          URLQueryItem(name: "Username", value: logingresponse?.username ?? ""),
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
                    message="Success!"
                    showToast.toggle()
                }
                else{
                    message="Failed!"
                    showToast.toggle()
                }
            }
        }.resume()
    }
    
    private func AddStatus(stock: String, vin: String, status: String){
        enteredStatus = ""
        let queryItems = [URLQueryItem(name: "Token", value: logingresponse?.token ?? ""),
                          URLQueryItem(name: "dealerid", value: String(logingresponse?.dealerId ?? "0")),
                          URLQueryItem(name: "strStockNo", value: stock),
                          URLQueryItem(name: "strVIN", value: vin),
                          URLQueryItem(name: "Username", value: logingresponse?.username ?? ""),
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
                    message="Success!"
                    showToast.toggle()
                }
                else{
                    message="Failed!"
                    showToast.toggle()
                }
            }
        }.resume()
    }
    
    private func checkScannedVehicleList(){
        if newVehicleScanned == false{
            toastMessage = true
            //ToastMessageView(message: "Already Scanned", isPresented: $toastMessage)
            //Alert(title: Text("Hello"))
        }
    }
    
    private func SendToDataBase(vehicleToUpdate: Vehicle) -> Bool {
        var finalLoc = ""
        var returnType = false
        if vehicleLocation != "_"{
            finalLoc=vehicleLocation
        }
        let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMddHHmmss"
        let queryItems = [URLQueryItem(name: "Token", value: logingresponse?.token ?? ""),
                          URLQueryItem(name: "dealerid", value: String(logingresponse?.dealerId ?? "0")),
                          URLQueryItem(name: "strStockNo", value: vehicleToUpdate.stockNo),
                          URLQueryItem(name: "strVIN", value: vehicleToUpdate.vin),
                          URLQueryItem(name: "strLotLocation",value: finalLotLocation),
                          URLQueryItem(name: "dtScanned", value: formatter.string(from: Date())),
                          URLQueryItem(name: "strColor", value: vehicleToUpdate.color),
                          URLQueryItem(name: "bScanned", value: "true"),
                          URLQueryItem(name: "Username", value: logingresponse?.username ?? ""),
                          URLQueryItem(name: "vehicleType", value: vehicleToUpdate.vType),
                          URLQueryItem(name: "strLocation", value: finalLoc)]
        
        let url = URL(string: baseURL.URL+"VehWizAPI/UpdateVehicles")!
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
                do {
                    let decoder = JSONDecoder()
                    let vehicleResp = try decoder.decode(Vehicle.self, from: data)
                    if vehicleResp.vin == vehicleToUpdate.vin{
                        returnType = true
                    }
                } catch {
                    // Handle the JSON decoding error
                    print("JSON decoding error: \(error)")
                }
            }
        }.resume()
        return returnType
    }
    private var cameraButton: some View {
        Button(action: {
            isShowingScanner=true
        }) {
            Image(systemName: "camera")
        }
    }
    func speakText(textToSpeak: String) {
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        speechSynthesizer.speak(utterance)
    }
    private func openMaps(latitude: Double, longitude: Double) {
        let coordinates = "\(latitude),\(longitude)"
        let mapURL = "http://maps.apple.com/?ll=\(coordinates)&t=h&z=21"
        guard let url = URL(string: mapURL) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    func removeFirstAndLastCharacter(_ str: String) -> String {
        let start = str.index(str.startIndex, offsetBy: 1)
        let end = str.index(str.endIndex, offsetBy: -1)
        return String(str[start..<end])
    }
}

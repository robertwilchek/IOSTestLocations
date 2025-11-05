//
//  VehicleWizardAppApp.swift
//  VehicleWizardApp
//
//  Created by robert wilchek on 6/13/23.
//

import SwiftUI

@main
struct VehicleWizardAppApp: App {
    @StateObject private var loginResponseHolder = LoginResponseHolder()
    @StateObject private var registerDeviceResponseHolder = RegisterDeviceResponseHolder()
    @StateObject private var locationManager = LocationManager()
    @State private var validationComplete = false
    @State private var registerDeviceView = false
    //@State public var baseURL = "http://40.117.173.178/"
    @StateObject var baseURL = BaseURL()
    let persistenceController = PersistenceController.shared
    //@AppStorage("selectedTheme") private var selectedTheme = ""
    //@AppStorage("selectedColors") private var selectedColors = ""
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                let deviceResponse = CheckIsDeviceRegistered()
                if deviceResponse == "Registered"{
                    if loginResponseHolder.loginResponse == nil {
                        LoginView(onLoginSuccess: { response in
                            loginResponseHolder.loginResponse = response
                        })
                    } else {
                        MainView(loginResponseHolder: loginResponseHolder, loginResponse: loginResponseHolder.loginResponse)
                    }
                }
                else if deviceResponse == "NotRegistered"{
                    //Register Screen
                    //RegisterDeviceView(validationComplete: $validationComplete)
                    if registerDeviceResponseHolder.validation == nil {
                        RegisterDeviceView(onValidationComplete: { response in
                            registerDeviceResponseHolder.validation = response
                        })
                    } else {
                        if loginResponseHolder.loginResponse == nil {
                            LoginView(onLoginSuccess: { response in
                                loginResponseHolder.loginResponse = response
                            })
                        } else {
                            MainView(loginResponseHolder: loginResponseHolder, loginResponse: loginResponseHolder.loginResponse)
                        }
                    }
                }
                else if deviceResponse == "Disabled"{
                    //Out of limit screen
                    MessageView(message: "App connect has been disabled,\nPlease contact the administrator.")
                }
            }
            //.preferredColorScheme(selectedTheme == "Light" ? .light : .dark)
            //.accentColor(themeColor)
            //.foregroundColor(themeColor)
            //.background(Color.brown)
            .onAppear {
                locationManager.requestAuthorizationIfNeeded()
                locationManager.startContinuousUpdates()
            }
            .onDisappear {
                locationManager.stopContinuousUpdates()
            }
            .environmentObject(locationManager)
        }
    }
    
    /*var themeColor: Color {
        if(selectedColors != ""){
            if selectedColors == "White"{
                return .white
            }
            else if selectedColors == "Light Gray"{
                let lightGrayColor = UIColor(named: "CustomLightGrayColor") ?? UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
                return Color(lightGrayColor)
            }
            else if selectedColors == "Light Green"{
                let lightGreenColor = UIColor(named: "CustomLightGreenColor") ?? UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
                return Color(lightGreenColor)
            }
            else if selectedColors == "Black"{
                return .black
            }
            else if selectedColors == "Dark Gray"{
                let darkGrayColor = UIColor(named: "CustomDarkGrayColor") ?? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                return Color(darkGrayColor)
            }
            else if selectedColors == "Navy Blue"{
                let navyBlueColor = UIColor(named: "CustomNavyBlueColor") ?? UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0)
                return Color(navyBlueColor)
            }
            else{
                if selectedTheme == "Dark"{
                    return .white
                }
                else{
                    return .black
                }
            }
        }
        else{
            let darkGrayColor = UIColor(named: "CustomDarkGrayColor") ?? UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            return Color(darkGrayColor)
        }
    }*/
    
    private func CheckIsDeviceRegistered() -> String{
        /*return "Registered"
         return "NotRegistered"
         return "OutOfLimit"*/
        
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else { return "" }
        var resp = ""
        let semaphore = DispatchSemaphore (value: 0)
        var request = URLRequest(url: URL(string: baseURL.URL+"VehWizAPI/CheckIsDeviceRegistered?deviceId="+deviceID)!,timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                semaphore.signal()
                return
            }
            resp=String(data: data, encoding: .utf8)!
            print(String(data: data, encoding: .utf8)!)
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        return String(resp.dropLast(1).dropFirst(1))
    }
}

class LoginResponseHolder: ObservableObject {
    @Published var loginResponse: LoginResponse?
}

class RegisterDeviceResponseHolder: ObservableObject {
    @Published var validation: String?
}
class BaseURL: ObservableObject {
  @Published var URL = "https://www.ssivehiclewiz.com/"
}

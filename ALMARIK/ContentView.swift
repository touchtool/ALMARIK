import SwiftUI
import MapKit
import Firebase

struct ContentView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var isRegistering = false
    @State private var annotations: [CustomPointAnnotation] = []
    @State private var selectedAnnotation: CustomPointAnnotation?
    @State private var isPopupPresented: Bool = false
    @State private var isEditPopupPresented: Bool = false
    @State private var editPopupAnnotation: CustomPointAnnotation?
    @State private var selectedAnnotationIndex: Int?
    @State private var searchText = ""
    @State private var results = [MKMapItem]()
    @State private var selectedSearchResult: MKMapItem?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 13.736717, longitude: 100.523186),
        span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
    )
    @State private var showSearchResults = true
    
    
    let firebaseManager = FirebaseManager()
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            NavigationView {
                VStack(spacing: 0){
                    NavigationBarView(
                        isLoggedIn: $isLoggedIn,
                        LeftIcon: "pencil",
                        RightIcon: "eraser"
                    )
                    .padding(.horizontal, 15)
                    .padding(.bottom)
                    .shadow(color: Color.brown.opacity(0.05), radius: 5, x: 0, y: 5)
                    .background(Color.white, ignoresSafeAreaEdges: .all)
                    if isLoggedIn {
                        ZStack {
                            MapView(annotations: $annotations, selectedAnnotation: $selectedAnnotation, isPopupPresented: $isPopupPresented, isEditPopupPresented: $isEditPopupPresented, editPopupAnnotation: $editPopupAnnotation, selectedAnnotationIndex: $selectedAnnotationIndex,
                                    region: $region,
                                    selectedCoordinate: $selectedCoordinate)
                            .overlay(alignment: .top) {
                                VStack{
                                    TextField("Search for a location...", text: $searchText)
                                        .font(.subheadline)
                                        .padding(12)
                                        .background(.white)
                                        .cornerRadius(15)
                                        .shadow(radius: 10)
                                    // List of search results
                                    if showSearchResults {
                                        SearchResultView(results: results, didSelectItem: { selectedMapItem in
                                            didSelectSearchResult(selectedMapItem)
                                            showSearchResults = false
                                        })
                                        .background(Color.white)
                                        .frame(maxWidth: .infinity)
                                    }
                                    
                                }
                                .padding(.leading)
                                .padding(.trailing)
                                .padding(.top, 20)
                            }
                            .onSubmit(of: .text) {
                                print("search for location \($searchText)")
                                Task { await searchPlaces() }
                                showSearchResults = true
                                
                            }
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                print("Map tapped")
                            }
                            .onAppear {
                                // Fetch annotations and convert them to CustomPointAnnotation
                                firebaseManager.fetchAnnotations { annotationDataArray in
                                    var customAnnotations: [CustomPointAnnotation] = []
                                    for annotationData in annotationDataArray {
                                        let customAnnotation = CustomPointAnnotation()
                                        customAnnotation.coordinate = CLLocationCoordinate2D(latitude: annotationData.latitude, longitude: annotationData.longitude)
                                        customAnnotation.title = annotationData.title
                                        customAnnotation.subtitle = annotationData.description
                                        customAnnotation.imageName = annotationData.imageName
                                        customAnnotation.id = annotationData.id
                                        customAnnotation.endDate = annotationData.endDate
                                        let currentDateTime = Date()
                                        
                                        if (currentDateTime <= annotationData.endDate ?? currentDateTime){
                                            customAnnotations.append(customAnnotation)
                                        }
                                    }
                                    
                                    // Now, update the annotations array with the custom annotations
                                    self.annotations = customAnnotations
                                }
                            }
                            if isPopupPresented, let annotation = selectedAnnotation, !isEditPopupPresented {
                                PopupView(annotation: annotation,
                                          isPopupPresented: $isPopupPresented,
                                          annotations: $annotations)
                                .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                                .zIndex(1)
                                .background(Color("darkbrownopacity"), ignoresSafeAreaEdges: .all)
                                
                            }
                            
                            // Conditionally present the edit popup
                            if isEditPopupPresented, let annotation = editPopupAnnotation {
                                EditPopupView(annotation: annotation,
                                              isEditPopupPresented: $isEditPopupPresented,
                                              annotations: $annotations,
                                              selectedAnnotationIndex: $selectedAnnotationIndex)
                                .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
                                .zIndex(1)
                                .background(Color("darkbrownopacity"), ignoresSafeAreaEdges: .all)
                                
                            }
                        }
                    } else {
                        LoginView(email: $email, password: $password, isLoggedIn: $isLoggedIn, isRegistering: $isRegistering)
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    // Function to handle selection of map item
    func didSelectSearchResult(_ mapItem: MKMapItem) {
        // Add your logic here, such as updating the selected annotation
        print("Selected location: \(mapItem.name ?? "")")
        // Update the region to center on the selected coordinate and span appropriately
        region = MKCoordinateRegion(
            center: mapItem.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        // Update the selected search result
        selectedSearchResult = mapItem
        // Update the selected coordinate
        selectedCoordinate = mapItem.placemark.coordinate
    }
}

extension ContentView {
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText.isEmpty ? "landmark" : searchText
        
        let thailandCoordinates = CLLocationCoordinate2D(latitude: 13.736717, longitude: 100.523186)
        let region = MKCoordinateRegion(center: thailandCoordinates, latitudinalMeters: 1000000, longitudinalMeters: 1000000)
        
        request.region = region
        
        let results = try? await MKLocalSearch(request: request).start()
        self.results = results?.mapItems ?? []
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SearchResultView: View {
    var results: [MKMapItem]
    var didSelectItem: (MKMapItem) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(results, id: \.self) { mapItem in
                    VStack(alignment: .leading){
                        Text(mapItem.name ?? "Unknown Location")
                            .fontWeight(.bold)
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                        Text(mapItem.placemark.formattedAddress ?? "No Address")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                            .frame(maxWidth: .infinity)
                    }
                    .onTapGesture {
                        didSelectItem(mapItem)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

extension MKPlacemark {
    var formattedAddress: String {
        var addressString = ""
        
        if let street = thoroughfare {
            addressString += street
        }
        if let city = locality {
            addressString += ", \(city)"
        }
        if let state = administrativeArea {
            addressString += ", \(state)"
        }
        if let postalCode = postalCode {
            addressString += " \(postalCode)"
        }
        if let country = country {
            addressString += ", \(country)"
        }
        
        return addressString.isEmpty ? "Address unavailable" : addressString
    }
}



struct LoginView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoggedIn: Bool
    @Binding var isRegistering: Bool
    @State private var isToast: Bool = false
    @State private var message: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Text("Login")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("darkerbrown"))
                        .cornerRadius(15)
                    VStack{
                        VStack(alignment: .leading){
                            Text("Email")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(alignment: .leading)
                                .padding(.leading)
                                .padding(.trailing)
                            VStack{
                                TextField("", text: $email, prompt: Text("Email").foregroundStyle(.white))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.white)
                            }
                            .padding(.leading)
                            .padding(.trailing)
                            .padding(.bottom)
                            Text("Password")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(alignment: .leading)
                                .padding(.leading)
                                .padding(.trailing)
                            VStack{
                                SecureField("", text: $password, prompt: Text("Password").foregroundStyle(.white))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.white)
                            }
                            .padding(.leading)
                            .padding(.trailing)
                        }
                        .padding()
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                // Add login logic here
                                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                                    if let error = error {
                                        print("Error logging in: \(error.localizedDescription)")
                                        // Display toast message if login fails
                                        isToast = true
                                        message = "Login failed: \(error.localizedDescription)"
                                    } else {
                                        print("User logged in successfully")
                                        isLoggedIn = true
                                    }
                                }
                            }){
                                Text("Login")
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding()
                            Spacer()
                        }
                        .background(Color("darkerbrown"))
                        .cornerRadius(15)
                        .padding(.leading)
                        .padding(.trailing)
                        Button(action: {
                            isRegistering = true
                        }) {
                            NavigationLink(destination: RegisterView(isRegistering: $isRegistering, isLoggedIn: $isLoggedIn), isActive: $isRegistering) {
                                Text("Register").foregroundStyle(.white)
                                    .padding(.bottom)
                                    .underline()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color("darkbrown"))
                    .cornerRadius(15)
                }
                .padding()
                .padding()
                .background(Color("darkbrownopacity"))
                
                // Toast message
                if isToast {
                    VStack {
                        Spacer()
                        Toast(isShowing: $isToast, message: $message, duration: 5)
                    }
                }
            }
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarBackButtonHidden(true)
    }
}



struct RegisterView: View {
    @Binding var isRegistering: Bool
    @Binding var isLoggedIn: Bool
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isToast: Bool = false
    @State private var message: String = ""
    
    var body: some View {
        VStack(spacing: 0){
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                Header(isLoggedIn: $isLoggedIn)
                VStack {
                    Text("Register")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("darkerbrown"))
                        .cornerRadius(15)
                    VStack{
                        VStack{
                            VStack(alignment: .leading){
                                Text("Email")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(alignment: .leading)
                                    .padding(.leading)
                                    .padding(.trailing)
                                VStack{
                                    TextField("", text: $email, prompt: Text("Email").foregroundStyle(.white))
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.white)
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.white)
                                }
                                .padding(.leading)
                                .padding(.trailing)
                                .padding(.bottom)
                                Text("Password")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(alignment: .leading)
                                    .padding(.leading)
                                    .padding(.trailing)
                                VStack{
                                    SecureField("", text: $password, prompt: Text("Password").foregroundStyle(.white))
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.white)
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.white)
                                }
                                .padding(.leading)
                                .padding(.trailing)
                                Text("Confirm Password")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(alignment: .leading)
                                    .padding(.leading)
                                    .padding(.trailing)
                                VStack{
                                    SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundStyle(.white))
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .foregroundColor(.white)
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.white)
                                }
                                .padding(.leading)
                                .padding(.trailing)
                            }
                            .padding()
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                if password == confirmPassword {
                                    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                                        if let error = error {
                                            print("Error registering user: \(error.localizedDescription)")
                                            isToast = true
                                            message = "Registration failed: \(error.localizedDescription)"
                                        } else {
                                            print("User registered successfully")
                                            isRegistering = false
                                        }
                                    }
                                } else {
                                    isToast = true
                                    message = "Passwords do not match"
                                }
                            }) {
                                Text("Register")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            Spacer()
                        }
                        .background(Color("darkerbrown"))
                        .cornerRadius(15)
                        .padding(.leading)
                        .padding(.trailing)
                        Button(action: {
                            isRegistering = false
                        }){
                            Text("Sign in").foregroundStyle(.white)
                                .padding(.bottom)
                                .underline()
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color("darkbrown"))
                    .cornerRadius(15)
                }
                .padding()
                .padding()
                .background(Color("darkbrownopacity"))
                
                // Show the toast message if passwords don't match
                if isToast {
                    VStack {
                        Spacer()
                        Toast(isShowing: $isToast, message: $message, duration: 5)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.keyboard)
    }
}

struct Header: View{
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        HStack {
            Text("ALMARIK")
                .font(.title)
                .foregroundColor(.white)
                .padding(.leading, 20)
            Spacer()
            Button(action: logout){
                Text("Logout")
                    .foregroundColor(.white)
                    .padding(.trailing, 20)
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}


struct NavigationBarModifier: ViewModifier {
    
    var backgroundColor: UIColor?
    var titleColor: UIColor?
    
    init(backgroundColor: UIColor?, titleColor: UIColor?) {
        self.backgroundColor = backgroundColor
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = backgroundColor
        coloredAppearance.titleTextAttributes = [.foregroundColor: titleColor ?? .white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor ?? .white]
        
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }
    
    func body(content: Content) -> some View {
        ZStack{
            content
            VStack {
                GeometryReader { geometry in
                    Color(self.backgroundColor ?? .clear)
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
            .zIndex(0)
        }
    }
}

extension View {
    
    func navigationBarColor(backgroundColor: UIColor?, titleColor: UIColor?) -> some View {
        self.modifier(NavigationBarModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }
    
}

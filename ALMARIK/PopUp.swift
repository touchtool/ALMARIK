//
//  PopUp.swift
//  ALMARIK
//
//  Created by ninew on 15/4/2567 BE.
//

import SwiftUI

struct PopupView: View {
    var annotation: CustomPointAnnotation
    @Binding var isPopupPresented: Bool
    @Binding var annotations: [CustomPointAnnotation]
    
    @State private var title: String = ""
    @State private var description: String = "Write Description"
    @State private var selectedImageIndex: Int = 0
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    
    let imageNames = ["danger", "safe", "disaster"]
    let firebaseManager = FirebaseManager() // FirebaseManager instance
    
    var body: some View {
        ScrollView {
            Text("Create Information Marker")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.white)
                .background(Color("darkerbrown"))
                .cornerRadius(15)
                .padding(.leading, 10)
                .padding(.trailing, 10)
            VStack {
                Button(action: {
                    isPopupPresented = false
                }){
                    Image(systemName: "xmark")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(Color.gray)
                }
                .padding(.top)
                .padding(.trailing)
                .frame(maxWidth: .infinity)
                Text("Title")
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.bold)
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                    .padding(.top, 10)
                VStack{
                    TextField("", text: $title, prompt: Text("Title").foregroundStyle(.gray.opacity(0.5)))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.black)
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                }
                .padding(.all, 10)
                Text("Description")
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.bold)
                
                TextEditor(text: $description)
                    .contentMargins(.horizontal, 0)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 5)
                    .padding(.trailing, 5)
                    .frame(width: 300, height: 225)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.gray.opacity(0.8), lineWidth: 1)
                    )
                    .lineLimit(20)
                    .foregroundColor(description == "Write Description" ? .gray : .primary)
                    .onTapGesture {
                        if description == "Write Description" {
                            description = ""
                        }
                    }
                
                let minimumDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
                Text("Date")
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.bold)
                DatePicker("Start Date:", selection: $selectedStartDate, in: minimumDate..., displayedComponents: .date)
                    .padding(.leading, 20)
                    .padding(.trailing)
                
                DatePicker("End Date:", selection: $selectedEndDate, in: minimumDate..., displayedComponents: .date)
                    .padding(.leading, 20)
                    .padding(.trailing)
                
                Text("Marker Icon")
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontWeight(.bold)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<imageNames.count) { index in
                            Image(imageNames[index])
                                .resizable()
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    selectedImageIndex = index
                                }
                                .border(selectedImageIndex == index ? Color.blue : Color.clear, width: 2)
                        }
                    }
                    .padding()
                }
                VStack{
                    Button(action: {
                        let newAnnotation = CustomPointAnnotation()
                        newAnnotation.coordinate = annotation.coordinate
                        newAnnotation.title = title
                        newAnnotation.subtitle = description
                        newAnnotation.imageName = imageNames[selectedImageIndex]
                        
                        let calendar = Calendar.current
                        var interval = TimeInterval()
                        calendar.dateInterval(of: .day, start: &selectedEndDate, interval: &interval, for: Date())
                        let newSelectedEndDate = calendar.date(byAdding: .second, value: Int(interval-1), to: selectedEndDate)!
                        
                        let dataNew = AnnotationData(
                            title: newAnnotation.title ?? "",
                            description: newAnnotation.subtitle ?? "",
                            latitude: newAnnotation.coordinate.latitude,
                            longitude: newAnnotation.coordinate.longitude,
                            imageName: newAnnotation.imageName ?? "",
                            startDate: selectedStartDate,
                            endDate: newSelectedEndDate
                        )
                        
                        var annotationDataNew = dataNew
                        
                        firebaseManager.saveAnnotation(annotation: &annotationDataNew)
                        newAnnotation.id = annotationDataNew.id
                        annotations.append(newAnnotation)
                        
                        isPopupPresented = false
                        title = ""
                        description = ""
                        selectedImageIndex = 0
                    }){
                        Text("Save")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(Color.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
                    .padding(.bottom)
                    .foregroundStyle(Color.white)
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.leading)
            .padding(.trailing)
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct EditPopupView: View {
    var annotation: CustomPointAnnotation
    @Binding var isEditPopupPresented: Bool
    @Binding var annotations: [CustomPointAnnotation]
    @Binding var selectedAnnotationIndex: Int?
    
    @State private var title: String = ""
    @State private var description: String = "Write Description"
    @State private var selectedImageIndex: Int = 0 // Add state for selectedImageIndex
    @State private var isEditOpen: Bool = false
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    
    let firebaseManager = FirebaseManager() // FirebaseManager instance
    
    let imageNames = ["danger", "safe", "disaster"]
    
    var body: some View {
        VStack {
            if !isEditOpen {
                ScrollView {
                    Text("Detail")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .background(Color("darkerbrown"))
                        .cornerRadius(15)
                        .padding(.leading)
                        .padding(.trailing)
                    VStack {
                        if let selectedIndex = selectedAnnotationIndex {
                            if !annotations.isEmpty{
                                let selectedAnnotation =  annotations[selectedIndex]
                                
                                Button(action:{
                                    isEditPopupPresented = false
                                }){
                                    Image(systemName: "xmark")
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .foregroundStyle(Color.gray)
                                        .padding(.top)
                                        .padding(.trailing)
                                }
                                
                                HStack {
                                    Text("Title:")
                                        .fontWeight(.bold)
                                    Text(selectedAnnotation.title ?? "Not have title")
                                }         
                                .padding(.top)
                                .padding(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                VStack{
                                    Text("Description:")
                                        .fontWeight(.bold)
                                    Text(selectedAnnotation.subtitle ?? "Not have Description")
                                }
                                .padding(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Date")
                                    .padding(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fontWeight(.bold)
                                HStack{
                                    Text(selectedAnnotation.startDate ?? Date(), style: .date)
                                    Text("-")
                                    Text(selectedAnnotation.endDate ?? Date(), style: .date)
                                }
                                .padding(.leading, 10)
                                .frame(maxWidth: .infinity)
                                Spacer()
                                HStack{
                                    Button(action:{
                                        isEditOpen = true
                                    }){
                                        Text("Edit Information")
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .foregroundStyle(.white)
                                            .padding()
                                            .background(.blue)
                                            .cornerRadius(5)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.leading)
                                .padding(.trailing)
                                Button(action:{
                                    firebaseManager.deleteAnnotation(annotation: selectedAnnotation) { success in
                                        if success {
                                            annotations.remove(at: selectedIndex)
                                            
                                            isEditPopupPresented = false
                                            isEditOpen = false
                                        } else {
                                            print("Failed to delete annotation from Firestore")
                                        }
                                    }
                                }){
                                    Text("Delete")
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .foregroundStyle(.white)
                                        .padding()
                                        .background(.red)
                                        .cornerRadius(5)
                                }
                                .padding(.leading)
                                .padding(.trailing)
                                .padding(.bottom)
                                
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
                    .edgesIgnoringSafeArea(.all)
                }
            } else {
                // Edit section of the popup
                Text("Edit Information Marker")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
                    .background(Color("darkerbrown"))
                    .cornerRadius(15)
                    .padding()
                ScrollView {
                    VStack {
                        Button(action: {
                            isEditPopupPresented = false
                            isEditOpen = false
                        }){
                            Image(systemName: "xmark")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundStyle(Color.gray)
                                .padding(.top)
                                .padding(.trailing)
                        }
                        Text("Title")
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fontWeight(.bold)
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                            .padding(.top, 10)
                    }
                    VStack{
                        TextField("", text: $title,
                                  prompt: Text(annotation.title ?? "").foregroundStyle(Color.black)
                        )
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.black)
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                    }
                    .padding(.all, 10)
                    Text("Description")
                        .padding(.leading, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontWeight(.bold)
                    
                    TextEditor(text: $description)
                        .contentMargins(.horizontal, 0)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 5)
                        .padding(.trailing, 5)
                        .frame(width: 300, height: 225)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.gray.opacity(0.8), lineWidth: 1)
                        )
                        .lineLimit(20)
                        .foregroundColor(description == "Write Description" ? .gray : .primary)
                        .onAppear {
                            self.description = annotation.subtitle ?? ""
                        }
                        .onTapGesture {
                            if description == "Write Description" {
                                description = ""
                            }
                        }
                    let minimumDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
                    Text("Date")
                        .padding(.leading, 20)
                        .frame(maxWidth: .infinity, alignment: .leading) // Align text to the leading side
                        .fontWeight(.bold)
                    DatePicker("Start Date:", selection: $selectedStartDate, in: minimumDate..., displayedComponents: .date)
                        .onAppear {
                            selectedStartDate = self.annotation.startDate ?? Date()
                        }
                        .padding(.leading, 20)
                        .padding(.trailing)
                    
                    DatePicker("End Date:", selection: $selectedEndDate, in: minimumDate..., displayedComponents: .date)
                        .onAppear {
                            selectedEndDate = self.annotation.endDate ?? Date()
                        }
                        .padding(.leading, 20)
                        .padding(.trailing)
                    
                    Text("Marker Icon")
                        .padding(.leading, 20) // Add padding to the leading side
                        .frame(maxWidth: .infinity, alignment: .leading) // Align text to the leading side
                        .fontWeight(.bold)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(0..<imageNames.count) { index in
                                Image(imageNames[index])
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .onTapGesture {
                                        selectedImageIndex = index
                                    }
                                    .border(selectedImageIndex == index ? Color.blue : Color.clear, width: 2)
                            }
                        }
                        .padding()
                    }
                    VStack{
                        Button(action:{
                            // Update the selected annotation with new data
                            guard let index = annotations.firstIndex(where: { $0 == annotation }) else { return }
                            annotations[index].title = title
                            annotations[index].subtitle = description
                            annotations[index].imageName = imageNames[selectedImageIndex]
                            
                            let calendar = Calendar.current
                            var interval = TimeInterval()
                            calendar.dateInterval(of: .day, start: &selectedEndDate, interval: &interval, for: Date())
                            let newSelectedEndDate = calendar.date(byAdding: .second, value: Int(interval-1), to: selectedEndDate)!
                            
                            // Create AnnotationData from CustomPointAnnotation
                            let newData = AnnotationData(id: annotation.id,
                                                         title: title,
                                                         description: description,
                                                         latitude: annotation.coordinate.latitude,
                                                         longitude: annotation.coordinate.longitude,
                                                         imageName: imageNames[selectedImageIndex],
                                                         startDate: selectedStartDate,
                                                         endDate: newSelectedEndDate
                            )
                            
                            // Update marker information in Firestore
                            firebaseManager.updateAnnotation(annotation: annotation, with: newData) { success in
                                if success {
                                    // Update local annotations array
                                    if let index = selectedAnnotationIndex {
                                        annotations[index].title = title
                                        annotations[index].subtitle = description
                                        annotations[index].imageName = imageNames[selectedImageIndex]
                                        annotations[index].startDate = selectedStartDate
                                        annotations[index].endDate = newSelectedEndDate
                                    }
                                } else {
                                    print("Failed to update annotation in Firestore")
                                }
                            }
                            
                            // Update local annotations array
                            if let index = selectedAnnotationIndex {
                                annotations[index].title = title
                                annotations[index].subtitle = description
                                annotations[index].imageName = imageNames[selectedImageIndex]
                            }
                            
                            // Close the edit popup
                            isEditOpen = false
                            title = ""
                            description = ""
                            selectedImageIndex = 0
                            isEditPopupPresented = false
                            isEditOpen = false
                        }){
                            Text("Update")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundStyle(Color.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .padding(.bottom)
                        .foregroundStyle(Color.white)
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.bottom)
                }
                .background(Color.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.leading)
                .padding(.trailing)
            }
        }
    }
}


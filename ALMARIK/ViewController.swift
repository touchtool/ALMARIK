import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore
import FirebaseStorage

// Custom annotation class
class CustomPointAnnotation: MKPointAnnotation {
    var id: String? // Add an optional id field to store the Firestore document ID
    var imageName: String?
    var startDate: Date?
    var endDate: Date?
}

// Define Annotation model
struct AnnotationData: Codable {
    var id: String? // Add an optional id field to store the Firestore document ID
    var title: String
    var description: String
    var latitude: Double
    var longitude: Double
    var imageName: String
    var startDate: Date?
    var endDate: Date?
}

struct MapView: UIViewRepresentable {
    @Binding var annotations: [CustomPointAnnotation]
    @Binding var selectedAnnotation: CustomPointAnnotation?
    @Binding var isPopupPresented: Bool
    @Binding var isEditPopupPresented: Bool
    @Binding var editPopupAnnotation: CustomPointAnnotation?
    @Binding var selectedAnnotationIndex: Int?
    @Binding var region: MKCoordinateRegion
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    let db = Firestore.firestore() // Firestore reference
    let firebaseManager = FirebaseManager() // FirebaseManager instance
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // Set initial region to Thailand
        let thailandCoordinates = CLLocationCoordinate2D(latitude: 13.736717, longitude: 100.523186)
        let region = MKCoordinateRegion(center: thailandCoordinates, latitudinalMeters: 1000000, longitudinalMeters: 1000000)
        mapView.setRegion(region, animated: true)
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.removeAnnotations(view.annotations)
        
        // Add annotations with custom marker image
        for annotation in annotations {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            annotationView.image = UIImage(named: annotation.imageName ?? "default") // Use custom image or default if not specified
            view.addAnnotation(annotationView.annotation!)
        }
        
        if let selectedAnnotation = selectedAnnotation {
            view.selectAnnotation(selectedAnnotation, animated: true)
        }
        
        // Update the map region if selectedCoordinate is not nil
        if let coordinate = selectedCoordinate {
            view.setRegion(region, animated: true)
            // Clear the selected coordinate after updating the map
            selectedCoordinate = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            parent.createNewMarker(at: coordinate)
            
            parent.isPopupPresented = true
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let reuseIdentifier = "pin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let customPointAnnotation = annotation as? CustomPointAnnotation {
                annotationView?.image = UIImage(named: customPointAnnotation.imageName ?? "defaultImageName")
            }
            
            // Add a label to display the title below the marker
            let titleLabel = UILabel()
            titleLabel.text = annotation.title ?? ""
            titleLabel.font = UIFont.systemFont(ofSize: 12)
            titleLabel.numberOfLines = 0 // Allow multiple lines for long titles
            titleLabel.textAlignment = .center
            titleLabel.backgroundColor = UIColor.white
            titleLabel.layer.cornerRadius = 15
            titleLabel.clipsToBounds = true
            
            // Calculate label width dynamically based on the title length
            let labelWidth = titleLabel.intrinsicContentSize.width + 20 // Add some padding
            titleLabel.frame = CGRect(x: (-labelWidth+30) / 2, y: 35, width: labelWidth, height: 30) // Center the label under the marker
            
            annotationView?.detailCalloutAccessoryView = titleLabel
            
            annotationView?.addSubview(titleLabel)
            
            // Set a smaller size for the annotation view
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            parent.selectedAnnotation = nil
            parent.isPopupPresented = false
        }
        
        // Handle tap on existing annotation to show edit popup
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? CustomPointAnnotation else { return }
            
            if let index = parent.annotations.firstIndex(where: { $0 == annotation }) {
                parent.selectedAnnotationIndex = index
            }
            
            parent.editPopupAnnotation = annotation
            parent.isEditPopupPresented = true // Show edit popup
        }
    }
    
    func createNewMarker(at coordinate: CLLocationCoordinate2D) {
        let newAnnotation = CustomPointAnnotation()
        newAnnotation.coordinate = coordinate
        self.selectedAnnotation = newAnnotation
    }
}

//
//  FirebaseManager.swift
//  ALMARIK
//
//  Created by ninew on 15/4/2567 BE.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

// FirebaseManager class to handle Firestore and Storage operations
class FirebaseManager {
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    // Function to save annotation data to Firestore
    func saveAnnotation(annotation: inout AnnotationData) {
        do {
            let documentReference = try db.collection("annotations").addDocument(from: annotation)
            annotation.id = documentReference.documentID // Update the annotation with the generated document ID

        } catch {
            print("Error adding annotation to Firestore: \(error)")
        }
    }

    
    // Function to upload image to Firebase Storage
    func uploadImage(image: UIImage, imageName: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let storageRef = storage.reference().child("images/\(imageName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            guard let _ = metadata else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                }
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                    }
                    return
                }
                
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    // Function to fetch all annotations from Firestore
    func fetchAnnotations(completion: @escaping ([AnnotationData]) -> Void) {
        db.collection("annotations").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            var annotations: [AnnotationData] = []
            for document in documents {
                do {
                    if var annotationData = try? document.data(as: AnnotationData.self) {
                        annotationData.id = document.documentID // Assign document ID to the 'id' property
                        annotations.append(annotationData)
                    }
                } catch {
                    print("Error decoding annotation data: \(error.localizedDescription)")
                }
            }
            completion(annotations)
        }
    }
    
    // Function to update annotation data in Firestore
    func updateAnnotation(annotation: CustomPointAnnotation, with newData: AnnotationData, completion: @escaping (Bool) -> Void) {
        guard let documentID = annotation.id else {
            print("Annotation does not have an ID")
            completion(false)
            return
        }
        
        // Create an AnnotationData object from the newData CustomPointAnnotation
        let newDataObject = AnnotationData(
            title: newData.title,
            description: newData.description ,
            latitude: newData.latitude,
            longitude: newData.longitude,
            imageName: newData.imageName,
            startDate: newData.startDate,
            endDate: newData.endDate
        )
        
        // Update Firestore document with new data
        do {
            try db.collection("annotations").document(documentID).setData(from: newDataObject)
            completion(true)
        } catch {
            print("Error updating annotation: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func deleteAnnotation(annotation: CustomPointAnnotation, completion: @escaping (Bool) -> Void) {
        guard let documentID = annotation.id else {
            print("Annotation does not have an ID")
            completion(false)
            return
        }
        
        db.collection("annotations").document(documentID).delete { error in
            if let error = error {
                print("Error deleting annotation: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

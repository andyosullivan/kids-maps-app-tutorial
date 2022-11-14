//
//  ViewController.swift
//  BoredCarApp
//
//  Created by Andy O'Sullivan on 28/09/2022.
//
// Note all icons are from icons8.com - you'll need a license or to attribute their usage, see
// icons8.com for more details.

import UIKit
import GoogleMaps
import CoreLocation
import GooglePlaces

class ViewController: UIViewController, CLLocationManagerDelegate, NetworkServiceDelegate {
    
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    
    let smallCharacterImageArray =
    ["lion","witchSmall","monsterSmall","sealSmall","carSmall","firefighterSmall","pandaSmall"
    ,"planeSmall","astronautSmall"]
    
    let bigCharacterImageArray =
    ["lion80","witchBig","monsterBig","sealBig","carBig","firefighterBig","pandaBig"
    ,"planeBig","astronautBig"]
    
    var sourceCoordinates = CLLocationCoordinate2D()
    var destinationCoordinates = CLLocationCoordinate2D()
    
    var hasDestinationBeenEntered: Bool = false
    var didUserAskForTime: Bool = false
    
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBAction func onWhereAmI(_ sender: Any) {
        getUserLocation()
    }
    
    @IBAction func onSettingsButton(_ sender: Any) {
        iconView.alpha = 1.0
    }
    
    @IBOutlet weak var iconView: UIView!
   
    @IBOutlet weak var mainCharacterButton: UIButton!
    
    var selectedCharacter = 0
    
    @IBAction func onCharacterButton(_ sender: Any) {
        let button = sender as! UIButton
        let tag = button.tag
        mainCharacterButton.setImage(UIImage(named: bigCharacterImageArray[tag]), for: .normal)
        marker.icon = UIImage(named: smallCharacterImageArray[tag])
        selectedCharacter = tag
        iconView.alpha = 0.0
    }
    
    func setUpIconView() {
        iconView.layer.borderWidth = 5
        iconView.layer.borderColor = UIColor.purple.cgColor
        iconView.layer.cornerRadius = 30
    }
    
    @IBAction func onNewButton(_ sender: Any) {
        
        hasDestinationBeenEntered = false
        let autocompleteController = GMSAutocompleteViewController()
           autocompleteController.delegate = self

           // Specify the place data types to return.
           let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
                                                     UInt(GMSPlaceField.placeID.rawValue))
           autocompleteController.placeFields = fields

           // Specify a filter.
           let filter = GMSAutocompleteFilter()
        filter.types = ["address"]
          autocompleteController.autocompleteFilter = filter

           // Display the autocomplete view controller.
           present(autocompleteController, animated: true, completion: nil)
    }
    
    
    @IBAction func onHowLongToGoButton(_ sender: Any) {
        didUserAskForTime = true
        getUserLocation()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        // setUpLocation()
    }
    
    var placeName = ""
    @IBAction func onWhereAmIGoingButton(_ sender: Any) {
        if (hasDestinationBeenEntered) {
            addMarkerAndMoveToCoordinates()
        }else{
        let autocompleteController = GMSAutocompleteViewController()
           autocompleteController.delegate = self

           // Specify the place data types to return.
           let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
                                                     UInt(GMSPlaceField.placeID.rawValue))
           autocompleteController.placeFields = fields

           // Specify a filter.
           let filter = GMSAutocompleteFilter()
        filter.types = ["address"]
           autocompleteController.autocompleteFilter = filter

           // Display the autocomplete view controller.
           present(autocompleteController, animated: true, completion: nil)
        }
    }
    
    //for location
    let locationManager = CLLocationManager()
    let marker = GMSMarker()
    let destinationMarker = GMSMarker()

    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            placesClient = GMSPlacesClient.shared()
        
            // Create a GMSCameraPosition that tells the map to display the
            // coordinate -33.86,151.20 at zoom level 6.
            let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
            mapView.camera = camera
        
            setUpIconView()
        
      }
    
    // MARK: - location
    
    func didCompleteRouteRequest(result: String) {
        didUserAskForTime = false
        var temp = result
        temp.removeLast()
        let minutes = Int(temp)! / 60
        print(minutes)
        DispatchQueue.main.async() {
            self.minutesLabel.text = "\(minutes) mins"
        }
    }
    
    func getUserLocation(){
        let manager = CLLocationManager()
        locationManager.delegate = self
        if (manager.authorizationStatus == .authorizedWhenInUse)
        || (manager.authorizationStatus == .authorizedAlways) {
            print("location authorised")
            //gpsLabel.textColor = UIColor.green
            //gpsLabel.text = "GPS enabled"
            locationManager.startUpdatingLocation()
        }else{
            print("location not authorised")
            //gpsLabel.textColor = UIColor.red
            //gpsLabel.text = "GPS not enabled!"
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.delegate = nil
        locationManager.stopUpdatingLocation()
        let location = locations.first!
    
        print("latitude: \(location.coordinate.latitude), longitude: \(location.coordinate.longitude)")
        

        let newLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let newCam = GMSCameraUpdate.setTarget(newLocation)
        mapView.animate(with: newCam)
        mapView.animate(toZoom: 12)
        
        //marker.map = nil
        marker.position = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        // marker.title = "Where you are"
        // marker.snippet = "Okay?"
        marker.icon = UIImage(named: smallCharacterImageArray[selectedCharacter])
        marker.map = mapView
        
        sourceCoordinates =  CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        if didUserAskForTime {
            let calls = NetworkCalls()
            calls.delegate = self
            //need to get new source before getting distance to destination
            if hasDestinationBeenEntered {
                calls.postRoute(startCoordinates: sourceCoordinates, destinationCoordinates: destinationCoordinates)
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            //gpsLabel.textColor = UIColor.green
            //gpsLabel.text = "GPS enabled"
            locationManager.startUpdatingLocation()
            break
        default:
            //gpsLabel.textColor = UIColor.red
            //gpsLabel.text = "GPS not enabled!"
            print("location permission not granted")
        }
    }
    
    //MARK: - places
    
    private var placesClient: GMSPlacesClient!
    
    // A hotel in Saigon with an attribution.
    var placeID = ""

    func getLatLongFromPlaceId () {
        // Specify the place data types to return.
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.coordinate.rawValue) |
                                                  UInt(GMSPlaceField.placeID.rawValue))
        
        placesClient?.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil, callback: {
          (place: GMSPlace?, error: Error?) in
          if let error = error {
            print("An error occurred: \(error.localizedDescription)")
            return
          }
          if let place = place {
            // self.lblName?.text = place.name
              print("The selected place coordinate is: \(place.coordinate)")
              self.destinationCoordinates = place.coordinate
              self.hasDestinationBeenEntered = true
              self.addMarkerAndMoveToCoordinates()
          }else{
              print("hmm, here");
          }
        })
    }
    
    func addMarkerAndMoveToCoordinates(){
        print("addMarkerAndMoveToCoordinates called")
        // Center the camera on Vancouver, Canada
        let newLocation = destinationCoordinates
        let newCam = GMSCameraUpdate.setTarget(newLocation)
        mapView.animate(with: newCam)
        mapView.animate(toZoom: 12)
        
        //destinationMarker.map = nil
        destinationMarker.position = destinationCoordinates
        destinationMarker.title = placeName
        //destinationMarker.snippet = "Okay?"
        destinationMarker.icon = UIImage(named: "home")
        destinationMarker.map = mapView
        /*DispatchQueue.main.async() {
            
        }*/
    }


}

extension ViewController: GMSAutocompleteViewControllerDelegate {

  // Handle the user's selection.
  func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
      print("Place name: \(place.name ?? "placename")")
      print("Place ID: \(place.placeID ?? "")")
      print("Place attributions: \(String(describing: place.attributions))")
      self.placeID = place.placeID ?? "nil"
      self.getLatLongFromPlaceId()
      self.placeName = (place.name ?? "")
      /*DispatchQueue.main.async() {
          self.destinationLabel.text = place.name ?? ""
      }*/
      dismiss(animated: true, completion: nil)
  }

  func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
    // TODO: handle the error.
    print("Error: ", error.localizedDescription)
  }

  // User canceled the operation.
  func wasCancelled(_ viewController: GMSAutocompleteViewController) {
    dismiss(animated: true, completion: nil)
  }

  // Turn the network activity indicator on and off again.
  func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
  }

  func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }

}

//
//  ViewController.swift
//  MapApp
//
//  Created by yosef elbosaty on 6/8/20.
//  Copyright © 2020 yosef elbosaty. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    //MARK:- Outlets Declaration
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapViewType: UISegmentedControl!
    

    //MARK:- Variables Declaration
    let locationManager = CLLocationManager()
    let regionInMeters : Double = 100
    var previousLocation : CLLocation!
    var directionsArray : [MKDirections] = []
    
    //MARK:- viewDidLoad Method:
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        segmentedControlDesign()
        }
    
    //MARK:- segmentedControlDesign
    func segmentedControlDesign(){
        mapViewType.layer.borderColor = UIColor.blue.cgColor
        mapViewType.layer.borderWidth = 3
        let segForeground = [NSAttributedString.Key.foregroundColor : UIColor.blue, NSAttributedString.Key.font : UIFont(name: "Georgia-Bold", size: 18)!]
        let segColor = [NSAttributedString.Key.foregroundColor : UIColor.white, NSAttributedString.Key.backgroundColor : UIColor.blue, NSAttributedString.Key.font : UIFont(name: "Georgia-Bold", size: 18)!]
        mapViewType.setTitleTextAttributes(segForeground, for: .normal)
        mapViewType.setTitleTextAttributes(segColor, for: .selected)
    }
    
    //MARK:- SegmentedControl Segments
    @IBAction func mapViewType(_ sender: Any) {
        switch mapViewType.selectedSegmentIndex{
        case 0: mapView.mapType = .standard
        case 1: mapView.mapType = .satellite
        case 2: mapView.mapType = .hybrid
        default: mapView.mapType = .standard
        }
    }
    
    //MARK:- goToButton Pressed
    @IBAction func goToButton(_ sender: Any) {
        getDirections()
    }
    
    //MARK:- Setup Map Method:
    func setupMap(){
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.showsTraffic = true
        locationManager.startUpdatingLocation()
        userRegion()
        previousLocation = getMapCenter(for: mapView)
    }
    
    //MARK:- userRegion Method:
    func userRegion(){
        //userLocation
        if let location = locationManager.location?.coordinate{
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
}

    //MARK:- CLLocationManagerDelegate
extension MapViewController : CLLocationManagerDelegate{
    
    //MARK:- setupLocationMangaer Method:
    func setupLocationMangaer(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    //MARK:- checkLocationAuthorization Method:
    func checkLocationAuthorization(){
        switch CLLocationManager.authorizationStatus(){
        case .authorizedWhenInUse:
            setupMap()
            break
        case .authorizedAlways:
            setupMap()
            break
        case .denied:
            let alert = UIAlertController(title: "Enable Location Services!", message: "Go to Settings->Privacy->Location Services->Turn Location Services On->Find MapApp in your application and give it whatever the permission you want.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:break
        @unknown default:
            print("new values added")
        }
    }
    
    //MARK:- checkLocationServices Method:
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            setupLocationMangaer()
            checkLocationAuthorization()
        }else{
            let alert = UIAlertController(title: "oops!", message: "Check that your location services is enabled.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
    //MARK:- CoreLocation Manager Delegate Methods:
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    //MARK:- getDirections Method:
    func getDirections(){
        //userLocation
        guard let location = locationManager.location?.coordinate else{return}
        let requset = requestDirections(from: location)
        let direction = MKDirections(request: requset)
        resetMapView(forNew: direction)
        direction.calculate { (response, error) in
            guard let response = response else{return}
            for route in response.routes{
                self.mapView.addOverlay(route.polyline)
              //  self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    //MARK:- requestDirections Method:
    func requestDirections(from coordinate: CLLocationCoordinate2D)-> MKDirections.Request{
        let destinationCoordinate = getMapCenter(for: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.requestsAlternateRoutes = true
        
        return request
    }
    //MARK:- resetMapView Method:
    func resetMapView(forNew direction:MKDirections){
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(direction)
       let _ = directionsArray.map {$0.cancel()}
    }
}

    //MARK:- MKMapViewDelegate
extension MapViewController : MKMapViewDelegate{
    
    //MARK:- getMapCenter Method:
    func getMapCenter(for mapView:MKMapView)->CLLocation{
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    //MARK:- regionDidChangeAnimated Method:
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getMapCenter(for: mapView)
        
        guard let previousLocation = self.previousLocation else{return}
        guard center.distance(from: previousLocation) > 5 else{return}
        self.previousLocation = center
        let geoCoder = CLGeocoder()
        geoCoder.cancelGeocode()
        geoCoder.reverseGeocodeLocation(center) { (placemarks, error) in
                if let placemarks = placemarks?.first{
                let streetNumber = placemarks.subThoroughfare ?? ""
                let streetName = placemarks.thoroughfare ?? ""
                let cityName = placemarks.locality ?? ""
                    let countryName = placemarks.country ?? ""
                    if !streetNumber.isEmpty || !streetName.isEmpty || !cityName.isEmpty{
                DispatchQueue.main.async {
                    self.addressLabel.text = "\(streetNumber) \(streetName) \(cityName)"
                        }
                    }else{
                DispatchQueue.main.async {
                    self.addressLabel.text = "\(countryName)"
                    }
                }
            }
        }
    }
    
    //MARK:- rendererFor Method:
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        return renderer
    }
}


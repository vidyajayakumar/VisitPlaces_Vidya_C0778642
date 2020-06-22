
import UIKit
import MapKit

class customPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(pinTitle:String, pinSubTitle:String, location:CLLocationCoordinate2D) {
        self.title = pinTitle
        self.subtitle = pinSubTitle
        self.coordinate = location
    }
}

class HomeViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var BtnTrans: UIButton!
    @IBOutlet weak var BtnWalk: UIButton!
    @IBOutlet weak var FAB: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    var destinationLoc: CLLocationCoordinate2D?
    var currentLoc: CLLocationCoordinate2D?
    var locations = UserDefaults.standard.value(forKey: "places") as! [[String: Any]]
    var selectedLocation: [String: Any]?

    //MARK: - Variables
    fileprivate let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonStyle()
//        userLocationUpdate()
        doubleTapGesture()
//        configureLocationServices()
    }

    func buttonStyle(){
        FAB.layer.cornerRadius = 24
        FAB.layer.masksToBounds = true
        FAB.backgroundColor = UIColor.white
        FAB.layer.zPosition = 1

        BtnWalk.layer.cornerRadius = 24
        BtnWalk.layer.masksToBounds = true
        BtnWalk.backgroundColor = UIColor.white
        BtnWalk.layer.zPosition = 1

        BtnTrans.layer.cornerRadius = 24
        BtnTrans.layer.masksToBounds = true
        BtnTrans.backgroundColor = UIColor.white
        BtnTrans.layer.zPosition = 1

        BtnTrans.isHidden = true

    }
    @IBAction func BtnZoomIn(_ sender: UIButton) {
        let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta/2, longitudeDelta: mapView.region.span.longitudeDelta/2)
        let region = MKCoordinateRegion(center: mapView.region.center, span: span)

        mapView.setRegion(region, animated: true)
    }
    @IBAction func BtnZoomOut(_ sender: UIButton) {
        let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta*2, longitudeDelta: mapView.region.span.longitudeDelta*2)
        let region = MKCoordinateRegion(center: mapView.region.center, span: span)

        mapView.setRegion(region, animated: true)
    }

    @IBAction func ButtonGetDirections(_ sender: UIButton) {
        getDirections(transType: .automobile)

    }
    @IBAction func ButtonWalking(_ sender: UIButton) {
        getDirections(transType: .walking)
    }
    @IBAction func ButtonTransit(_ sender: UIButton) {
        getDirections(transType: .any)
    }


    func doubleTapGesture() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleLongPress(gestureRecognizer:)))
        gestureRecognizer.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        mapView.isZoomEnabled = selectedLocation == nil ? false : true
//        configureLocationServices()
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.delegate = self
        getCurrentLoc()
        showSelectedLocationDetails()
    }

    func showSelectedLocationDetails() {
        guard let location = selectedLocation else { return }
//        removeAnnotation()
//        clearPoly()
        destinationLoc = CLLocationCoordinate2D(latitude: location["lat"] as! CLLocationDegrees, longitude: location["long"] as! CLLocationDegrees)
//        addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D(latitude: location["lat"] as! CLLocationDegrees, longitude: location["long"] as! CLLocationDegrees), title: location["name"] as? String)
        addAnnotationOnLocation(pointedCoordinate: destinationLoc!, title: location["name"] as? String)
    }



    func getCurrentLoc() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        }
        currentLoc = locationManager.location?.coordinate
        locationManager.startUpdatingLocation()
    }

    @objc func handleLongPress(gestureRecognizer: UITapGestureRecognizer) {

        let touchPoint: CGPoint = gestureRecognizer.location(in: mapView)
        let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        destinationLoc = newCoordinate
        lookUpcurrentLoc(with: newCoordinate) { placeMark in
            self.locations.append(["name": placeMark?.subLocality ?? "Favourite Place", "lat": newCoordinate.latitude, "long": newCoordinate.longitude])
            UserDefaults.standard.setValue(self.locations, forKey: "places")
            UserDefaults.standard.synchronize()
            self.navigationController?.popViewController(animated: true)
        }
        addAnnotationOnLocation(pointedCoordinate: newCoordinate, title: nil)
    }

    func lookUpcurrentLoc(with location: CLLocationCoordinate2D, completionHandler: @escaping (CLPlacemark?)
        -> Void ) {
        // Use the last reported location.
        let geocoder = CLGeocoder()

        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude),
                                        completionHandler: { (placemarks, error) in
                                            if error == nil {
                                                let firstLocation = placemarks?[0]
                                                completionHandler(firstLocation)
                                            }
                                            else {
                                                // An error occurred during geocoding.
                                                completionHandler(nil)
                                            }
        })
    }

    func addAnnotationOnLocation(pointedCoordinate: CLLocationCoordinate2D, title: String?) {
        destinationLoc = pointedCoordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = pointedCoordinate
        
        mapView.addAnnotation(annotation)
    }


    //    ==========================

    private func gesture(){
        mapView.delegate = self
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        mapView.addGestureRecognizer(longTapGesture)
    }


    @objc func longTap(sender: UIGestureRecognizer){
        print("long tap")
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
        }
    }

    func addAnnotation(location: CLLocationCoordinate2D){
        removeAnnotation()
        clearPoly()

        //        hideBtn()
        destinationLoc = location
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Get Directions here"
        annotation.subtitle = ""
        self.mapView.addAnnotation(annotation)
        print(location)
        //zoomToLatestLocation(with: destinationLoc)

    }

    func removeAnnotation(){
        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations( annotationsToRemove )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //    --------------------


    func userLocationUpdate(){
            currentLoc = locationManager.location?.coordinate
            //zoomToLatestLocation(with: currentLoc)
    }
    func clearPoly(){
        for poll in mapView.overlays {
            mapView.removeOverlay(poll)
        }
    }


    func getDirections(transType: MKDirectionsTransportType){
        if currentLoc == nil || destinationLoc == nil {
            clearPoly()
            userLocationUpdate()
            //            let alert : UIAlertView = UIAlertView(title: "No Destination!", message: "Long press to select a destination",       delegate: nil, cancelButtonTitle: "Okay")
            //            alert.show()

            let alert = UIAlertController(title: "No Destination!", message: "Long press to select a destination", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { action in
                switch action.style {
                case .default:
                    print("default")
                case .cancel:
                    print("cancel")
                case .destructive:
                    print("destructive")
                @unknown default:
                    fatalError()
                }
            }))
            self.present(alert, animated: true, completion: nil)

            print("no destination set")
        }
        else{
            userLocationUpdate()
            removeAnnotation()
            //            showBtn()
            clearPoly()
            //            let sourcePin = customPin(pinTitle: "Your location", pinSubTitle: "", location: currentLoc!)
            let destinationPin = customPin(pinTitle: "Destination Point", pinSubTitle: "", location: destinationLoc!)
            //            self.mapView.addAnnotation(sourcePin)
            self.mapView.addAnnotation(destinationPin)

            let sourcePlaceMark                 = MKPlacemark(coordinate: currentLoc!)
            let destinationPlaceMark            = MKPlacemark(coordinate: destinationLoc!)

            let directionRequest                = MKDirections.Request()
            directionRequest.source             = MKMapItem(placemark: sourcePlaceMark)
            directionRequest.destination        = MKMapItem(placemark: destinationPlaceMark)
            directionRequest.transportType      = transType
            directionRequest.requestsAlternateRoutes = true

            let directions = MKDirections(request: directionRequest)
            directions.calculate { (response, error) in
                guard let directionResonse = response else {
                    if let error = error {
                        print("we have error getting directions==\(error.localizedDescription)")
                    }
                    return
                }

                //                for route in directionResonse.routes {
                let route = directionResonse.routes[0]
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                let rect = route.polyline.boundingMapRect
                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                //                }
            }

            self.mapView.delegate = self

        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 4.0
            return renderer
        }

    }
    //    =======================
    //    =======================
    private func configureLocationServices(){
        locationManager.delegate = self

        let status = CLLocationManager.authorizationStatus()

        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }else if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: locationManager)
        }
    }

    private func beginLocationUpdates(locationManager: CLLocationManager){
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.stopUpdatingLocation()

    }

    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D){
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(zoomRegion, animated: true)
        currentLoc = coordinate
        locationManager.stopUpdatingLocation()

    }

}

//MARK: - CLLocationManagerDelegate Methods
extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did get latest Location")

        let location = locations.first! as CLLocation
        let currentLoc = location.coordinate
        self.currentLoc = currentLoc
        let coordinateRegion = MKCoordinateRegion(center: currentLoc, latitudinalMeters: 1500, longitudinalMeters: 1500)
        mapView.setRegion(coordinateRegion, animated: true)
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension HomeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var renderer: MKPolylineRenderer? = nil
        if let anOverlay = overlay as? MKPolyline {
            renderer = MKPolylineRenderer(polyline: anOverlay)
        }
        renderer?.strokeColor = UIColor(red: 0.0 / 255.0, green: 171.0 / 255.0, blue: 253.0 / 255.0, alpha: 1.0)
        renderer?.lineWidth = 10.0
        if let aRenderer = renderer {
            return aRenderer
        }
        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, viewFor annotationV: MKAnnotation) -> MKAnnotationView? {
        let identifier = "CustomerAnnotationView"
        var annotation = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        annotation?.isDraggable = true
        if annotation == nil {
            annotation = MKPinAnnotationView(annotation: annotationV, reuseIdentifier: identifier)
            annotation?.canShowCallout = true
            annotation?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            annotation?.annotation = annotationV
        }
        return annotation
    }
}



//=================
//===================
//=======================

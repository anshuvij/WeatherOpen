//
//  ViewController.swift
//  WeatherOpenWeather
//
//  Created by Mobile Apps Team on 2/9/21.
//

import UIKit
import CoreLocation

var vSpinner : UIView?
class ViewController: UIViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!

    var weatherManager = WeatherManager()
    var locationManager = CLLocationManager()
    var weatherModel = [WeatherModel]()
    var days = ["Today"]
    
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
        configureUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated: true)
        
    }
    
    //MARK: - Helpers
    func configureUI() {
        
        // Do any additional setup after loading the view.
        self.showSpinner(onView: self.view)
        
        
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    
        searchTextField.delegate = self
        weatherManager.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
      tableView.register(UINib(nibName: Constants.cellIdentifier, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        
    }
    

    
    
    func getWeatherData(coordinate : Coordinate)
    {
        weatherManager.fetchWeather(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    

    
    //MARK: - Actions
    @IBAction func currentLocation(_ sender: Any) {
        self.showSpinner(onView: self.view)
        locationManager.requestLocation()
    }
    
    
    @IBAction func textFieldTapped(_ sender: Any) {
        searchTextField.resignFirstResponder()
        searchTextField.endEditing(true)
        let acController = PlaceHelperVC()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
        
    }
    

}

//MARK:- UITextFieldDelegate
extension ViewController : UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        searchTextField.endEditing(true)
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        searchTextField.resignFirstResponder()
        searchTextField.text = ""
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.view.endEditing(true)
        searchTextField.endEditing(true)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        if textField.text != ""
        {
            return true
        }
        else
        {
            textField.placeholder = "Type Something"
            return false
        }
        
    }
}

//MARK:- WeatherManagerDelegate

extension ViewController : WeatherManagerDelegate
{
    func didUpdateWeather(_ weatherManager : WeatherManager, _ weather: [WeatherModel]) {
        self.removeSpinner()
        weatherModel.removeAll()
        weatherModel = weather
        
        DispatchQueue.main.async {
            self.temperatureLabel.text = weather[0].tempratureString
            self.cityLabel.text = weather[0].cityName
            self.conditionImageView.image = UIImage(systemName: weather[0].conditionName)
            self.tableView.reloadData()
           
        }
        
    }
    
    func didFailWithError(error: Error) {
        print(error)
        self.removeSpinner()
    }
}

//MARK:- CoreLocation

extension ViewController : CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let locations = locations.last{
            locationManager.stopUpdatingLocation()
            let lat = locations.coordinate.latitude
            let long = locations.coordinate.longitude
            weatherManager.fetchWeather(latitude: lat, longitude: long)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
//MARK:- UIViewController

extension UIViewController {
    
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
         vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}

//MARK:- PlaceHelperDelegate
extension ViewController : PlaceHelperDelegate {
    
    func selectedLocation(lat: Double?, lon: Double?, name : String?) {
       
        guard let lat = lat else { return }
        guard let lon = lon else { return }
    
        self.showSpinner(onView: self.view)
        weatherManager.fetchWeather(latitude: lat, longitude: lon)
        
    }
    
    
}

extension Date {
    static func getDates(forLastNDays nDays: Int) -> [String] {
        let cal = NSCalendar.current
        // start with today
        var date = cal.startOfDay(for: Date())

        var arrDates = [String]()

        for _ in 1 ..< nDays {
            // move back in time by one day:
            date = cal.date(byAdding: Calendar.Component.day, value: 1, to: date)!

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EE"
            let dateString = dateFormatter.string(from: date)
            arrDates.append(dateString)
        }
       // print(arrDates)
        return arrDates
    }
}

//MARK:- UITableViewDelegate
extension ViewController : UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return weatherModel.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
           let headerView = UIView()
           headerView.backgroundColor = UIColor.clear
           return headerView
       }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10.0
        }
}

//MARK:- UITableViewDataSource
extension ViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! TableViewCell
        
        cell.minTemp.text = "Min: \(weatherModel[indexPath.section].min_temp)°C"
        cell.maxTemp.text = "Max: \(weatherModel[indexPath.section].max_temp)°C"
        cell.dateTime.text = weatherModel[indexPath.section].conditionName
        print("conditionName : \(weatherModel[indexPath.section].conditionName)")
       // cell.cloudimage.image = UIImage(named: weatherModel[indexPath.section].conditionName)
        
        return cell
        
    }
    
    
}





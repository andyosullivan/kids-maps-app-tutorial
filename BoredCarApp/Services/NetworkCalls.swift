//
//  NetworkCalls.swift
//
//  Created by Andy O'Sullivan on 06/10/2022.
//

import Foundation
import CoreLocation

protocol NetworkServiceDelegate {
    func didCompleteRouteRequest(result: String)
}
class NetworkCalls {
    
    var delegate: NetworkServiceDelegate?
    
    func postRoute(startCoordinates: CLLocationCoordinate2D, destinationCoordinates: CLLocationCoordinate2D){
        print("postRoute called:")
        print(startCoordinates)
        print(destinationCoordinates)
        
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes?key=your_routes_api_key&fields=routes.duration,routes.distanceMeters")
        var request : URLRequest = URLRequest(url: url!)
        request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        
        let options = ["origin":["location":["latLng":["latitude": startCoordinates.latitude, "longitude": startCoordinates.longitude ]]]
        ,
                       "destination":["location":["latLng":["latitude": destinationCoordinates.latitude, "longitude": destinationCoordinates.longitude ]]]]
    
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: options, options: []) // pass dictionary to data object and set it as request body
            print("all good: \(String(describing: request.httpBody))")
        } catch let error {
            print(error.localizedDescription)
            print("json error")
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: options, options: [])
        let dataString = String(data: jsonData, encoding: .utf8)!
          print(dataString)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Do something...
            guard let httpResponse = response as? HTTPURLResponse, let receivedData = data
                else {
                    print("error: not a valid http response")
                    return
            }
            switch (httpResponse.statusCode) {
            case 200:
                //success response.
                print("200 success! \(String(describing: String(data: receivedData, encoding: .utf8)))")
                if data != nil {
                  do{
                       //here dataResponse received from a network request
                       let jsonResponse = try JSONSerialization.jsonObject(with:
                                              receivedData, options: []) as? [String:Any]
                      
                      
                      
                      print((jsonResponse!["routes"]! as AnyObject)) //Response result
                      let routes = jsonResponse!["routes"]
                      print(routes!)
                      
                      
                      if let results = jsonResponse!["routes"] as! [Any]?{
                          for result in results {
                              print(result)
                              if let locationDictionary = result as? [String : Any] {
                                  print(locationDictionary["duration"]!)
                                  let temp = locationDictionary["duration"]
                                  self.delegate?.didCompleteRouteRequest(result: temp as! String)
                              }
                              
                          }
                          
                      }
                    } catch let parsingError {
                       print("Error", parsingError)
                  }
                    
                }
                //self.delegate?.didCompleteRouteRequest(result: "whatevs")
                break
            case 400:
                print("400 no! \(String(describing: String(data: receivedData, encoding: .utf8)))")
                break
            default:
                print("default no! \(httpResponse.statusCode) all: \(httpResponse)")
                break
            }
        }
        task.resume()
    }
    
}


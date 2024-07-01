import Foundation

var COMMON_URL = "https://where-run-user"
var REGION_URL = "-skrgq3jc5a-du.a.run.app"

var USER_URL = COMMON_URL + REGION_URL + "/user"
var LOGIN_URL = COMMON_URL + REGION_URL + "/login"
var CARD_URL = COMMON_URL + REGION_URL + "/card"
var SCALE_URL = COMMON_URL + REGION_URL + "/scale"
var IMAGE_URL = "jupiter_image"

// var USER_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/user"
// var CARD_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/card"
// var SCALE_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/scale"

public func setRegion(regionName: String) {
    switch (regionName) {
    case "Korea":
        REGION_URL = "-skrgq3jc5a-du.a.run.app"
        IMAGE_URL = "jupiter_image"
    case "Canada":
        REGION_URL = "-mewcfgikga-pd.a.run.app"
        IMAGE_URL = "jupiter_image_can"
    case "US(East)":
        REGION_URL = "-redh4tjnwq-ue.a.run.app"
        IMAGE_URL = "jupiter_image_us_east"
    default:
        REGION_URL = "-skrgq3jc5a-du.a.run.app"
        IMAGE_URL = "jupiter_image"
    }
    
    USER_URL = COMMON_URL + REGION_URL + "/user"
    LOGIN_URL = COMMON_URL + REGION_URL + "/login"
    CARD_URL = COMMON_URL + REGION_URL + "/card"
    SCALE_URL = COMMON_URL + REGION_URL + "/scale"
}

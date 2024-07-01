import Foundation

var IS_OLYMPUS: Bool = false

let USER_SERVER_VERSION = "2024-06-12"
let BLACK_LIST_URL = "https://ap-northeast-2.client.olympus.tjlabs.dev/black"

let HTTP_PREFIX = "https://"
var REGION_PREFIX = "ap-northeast-2."
let OLYMPUS_SUFFIX = ".olympus.tjlabs.dev"
let OPERATING_SYSTEM = "iOS"

var REGION_NAME = "Korea"

var OLYMPUS_USER_URL = ""
var OLYMPUS_IMAGE_URL = ""

var USER_SUFFIX = "user"
var IMAGE_SUFFIX = "img"
var CSV_SUFFIX = "csv"

var USER_LOGIN_URL = ""
var USER_CARD_URL = ""
var USER_IMAGE_URL = ""
var USER_ORDER_URL = ""
var USER_SCALE_URL = ""
var USER_SECTOR_URL = ""
var USER_RC_URL = ""

var REC_RFD_URL = ""
var REC_UVD_URL = ""
var REC_UMD_URL = ""
var REC_RESULT_URL = ""
var REC_REPORT_URL = ""

var CALC_OSR_URL = ""
var CALC_FLT_URL = ""

public func setServerURL(region: String) {
    switch (region) {
    case "Korea":
        REGION_PREFIX = "ap-northeast-2."
        REGION_NAME = "Korea"
    case "Canada":
        REGION_PREFIX = "ca-central-1."
        REGION_NAME = "Canada"
    default:
        REGION_PREFIX = "ap-northeast-2."
        REGION_NAME = "Korea"
    }
    
    OLYMPUS_USER_URL = HTTP_PREFIX + REGION_PREFIX + "user" + OLYMPUS_SUFFIX
    OLYMPUS_IMAGE_URL = HTTP_PREFIX + REGION_PREFIX + "img" + OLYMPUS_SUFFIX
    
    USER_LOGIN_URL = OLYMPUS_USER_URL + "/" + USER_SERVER_VERSION + "/user"
    USER_CARD_URL = OLYMPUS_USER_URL + "/" + USER_SERVER_VERSION + "/card"
    USER_IMAGE_URL = OLYMPUS_IMAGE_URL
    USER_ORDER_URL = OLYMPUS_USER_URL + "/" + USER_SERVER_VERSION + "/order"
    USER_SCALE_URL = OLYMPUS_USER_URL + "/" + USER_SERVER_VERSION + "/scale"
    USER_SECTOR_URL = OLYMPUS_USER_URL + "/" + USER_SERVER_VERSION + "/sector"
    USER_RC_URL = OLYMPUS_USER_URL + "/" + USER_SERVER_VERSION + "/rc"
}

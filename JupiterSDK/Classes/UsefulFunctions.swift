import Foundation


public func getLocalTimeString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    dateFormatter.locale = Locale(identifier:"ko_KR")
    let nowDate = Date()
    let convertNowStr = dateFormatter.string(from: nowDate)
    
    return convertNowStr
}

public func getCurrentTimeInMilliseconds() -> Int
{
    return Int(Date().timeIntervalSince1970 * 1000)
}

public func getCurrentTimeInMillisecondsDouble() -> Double
{
    return (Date().timeIntervalSince1970 * 1000)
}

public func convertToDoubleArray(intArray: [Int]) -> [Double] {
    return intArray.map { Double($0) }
}

public func checkLevelDirection(currentLevel: Int, destinationLevel: Int) -> String {
    var levelDirection: String = ""
    let diffLevel: Int = destinationLevel - currentLevel
    if (diffLevel > 0) {
        levelDirection = "_D"
    }
    return levelDirection
}

public func removeLevelDirectionString(levelName: String) -> String {
    var levelToReturn: String = levelName
    if (levelToReturn.contains("_D")) {
        levelToReturn = levelName.replacingOccurrences(of: "_D", with: "")
    }
    return levelToReturn
}

public func findClosestValueIndex(to target: Int, in array: [Int]) -> Int? {
    guard !array.isEmpty else {
        return nil
    }

    var closestIndex = 0
    var smallestDifference = abs(array[0] - target)

    for i in 0..<array.count {
        let value = array[i]
        let difference = abs(value - target)
        if difference < smallestDifference {
            smallestDifference = difference
            closestIndex = i
        }
    }

    return closestIndex
}

public func countAllValuesInDictionary(_ dictionary: [String: [String]]) -> Int {
    var count = 0
    for (_, value) in dictionary {
        count += value.count
    }
    return count
}

public func calculateAccumulatedLength(userTrajectory: [TrajectoryInfo]) -> Double {
    var accumulatedLength = 0.0
    for unitTraj in userTrajectory {
        accumulatedLength += unitTraj.length
    }
    
    return accumulatedLength
}

public func compensateHeading(heading: Double) -> Double {
    var headingToReturn: Double = heading
    
    if (headingToReturn < 0) {
        headingToReturn = headingToReturn + 360
    }
    headingToReturn = headingToReturn - floor(headingToReturn/360)*360

    return headingToReturn
}

public func checkIsSimilarXyh(input: [Double]) -> Bool {
    var dh = input[2]
    if (dh >= 270) {
        dh = 360 - dh
    }
    
    if (dh < 20) {
        return true
    } else {
        return false
    }
}

public func checkDiagonal(userTrajectory: [TrajectoryInfo], DIAGONAL_CONDITION: Double) -> [TrajectoryInfo] {
    var accumulatedDiagonal = 0.0
    
    if (!userTrajectory.isEmpty) {
        let startHeading = userTrajectory[0].heading
        let headInfo = userTrajectory[userTrajectory.count-1]
        var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
        
        var headingFromHead = [Double] (repeating: 0, count: userTrajectory.count)
        for i in 0..<userTrajectory.count {
            headingFromHead[i] = compensateHeading(heading: userTrajectory[i].heading  - 180 - startHeading)
        }
        
        var trajectoryFromHead = [[Double]]()
        trajectoryFromHead.append(xyFromHead)
        for i in (1..<userTrajectory.count).reversed() {
            let headAngle = headingFromHead[i]
            xyFromHead[0] = xyFromHead[0] + userTrajectory[i].length*cos(headAngle*D2R)
            xyFromHead[1] = xyFromHead[1] + userTrajectory[i].length*sin(headAngle*D2R)
            trajectoryFromHead.append(xyFromHead)
            
            let trajectoryMinMax = getMinMaxValues(for: trajectoryFromHead)
            let dx = trajectoryMinMax[2] - trajectoryMinMax[0]
            let dy = trajectoryMinMax[3] - trajectoryMinMax[1]
            
            accumulatedDiagonal = sqrt(dx*dx + dy*dy)
            if (accumulatedDiagonal >= DIAGONAL_CONDITION) {
                let newTrajectory = getTrajectoryForDiagonal(from: userTrajectory, N: i)
                return newTrajectory
            }
        }
    }
    
    return userTrajectory
}

public func checkAccumulatedLength(userTrajectory: [TrajectoryInfo], LENGTH_CONDITION: Double) -> [TrajectoryInfo] {
    var accumulatedLength = 0.0
    
    var longTrajIndex: Int = 0
    var isFindLong: Bool = false
    var shortTrajIndex: Int = 0
    var isFindShort: Bool = false
    
    if (!userTrajectory.isEmpty) {
        let startHeading = userTrajectory[0].heading
        let headInfo = userTrajectory[userTrajectory.count-1]
        var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
        
        var headingFromHead = [Double] (repeating: 0, count: userTrajectory.count)
        for i in 0..<userTrajectory.count {
            headingFromHead[i] = compensateHeading(heading: userTrajectory[i].heading  - 180 - startHeading)
        }
        
        var trajectoryFromHead = [[Double]]()
        trajectoryFromHead.append(xyFromHead)
        accumulatedLength = userTrajectory[0].length
        
        for i in (1..<userTrajectory.count).reversed() {
            let headAngle = headingFromHead[i]
            let uvdLength = userTrajectory[i].length
            accumulatedLength += uvdLength
            
            if ((accumulatedLength >= LENGTH_CONDITION*2) && !isFindLong) {
                isFindLong = true
                print(getLocalTimeString() + " , (Jupiter) Length Check : isLong // index = \(i)")
                longTrajIndex = i
            }
            
            if ((accumulatedLength >= LENGTH_CONDITION) && !isFindShort) {
                isFindShort = true
                print(getLocalTimeString() + " , (Jupiter) Length Check : isShort // index = \(i)")
                shortTrajIndex = i
            }
            
            xyFromHead[0] = xyFromHead[0] + uvdLength*cos(headAngle*D2R)
            xyFromHead[1] = xyFromHead[1] + uvdLength*sin(headAngle*D2R)
            trajectoryFromHead.append(xyFromHead)
        }
        
        let trajectoryMinMax = getMinMaxValues(for: trajectoryFromHead)
        let width = trajectoryMinMax[2] - trajectoryMinMax[0]
        let height = trajectoryMinMax[3] - trajectoryMinMax[1]
        
        if (width <= 3 || height <= 3) {
            let newTrajectory = getTrajectoryForDiagonal(from: userTrajectory, N: longTrajIndex)
            return newTrajectory
        } else {
            let newTrajectory = getTrajectoryForDiagonal(from: userTrajectory, N: shortTrajIndex)
            return newTrajectory
        }
    }
    
    return userTrajectory
}

public func calculateAccumulatedDiagonal(userTrajectory: [TrajectoryInfo]) -> Double {
    var accumulatedDiagonal = 0.0
    
    if (!userTrajectory.isEmpty) {
        let startHeading = userTrajectory[0].heading
        let headInfo = userTrajectory[userTrajectory.count-1]
        var xyFromHead: [Double] = [headInfo.userX, headInfo.userY]
        
        var headingFromHead = [Double] (repeating: 0, count: userTrajectory.count)
        for i in 0..<userTrajectory.count {
            headingFromHead[i] = compensateHeading(heading: userTrajectory[i].heading  - 180 - startHeading)
        }
        
        var trajectoryFromHead = [[Double]]()
        trajectoryFromHead.append(xyFromHead)
        for i in (1..<userTrajectory.count).reversed() {
            let headAngle = headingFromHead[i]
            xyFromHead[0] = xyFromHead[0] + userTrajectory[i].length*cos(headAngle*D2R)
            xyFromHead[1] = xyFromHead[1] + userTrajectory[i].length*sin(headAngle*D2R)
            trajectoryFromHead.append(xyFromHead)
        }
        
        let trajectoryMinMax = getMinMaxValues(for: trajectoryFromHead)
        let dx = trajectoryMinMax[2] - trajectoryMinMax[0]
        let dy = trajectoryMinMax[3] - trajectoryMinMax[1]
        
        accumulatedDiagonal = sqrt(dx*dx + dy*dy)
    }
    
    return accumulatedDiagonal
}

public func getTrajectoryFromIndex(from userTrajectory: [TrajectoryInfo], index: Int) -> [TrajectoryInfo] {
    var result: [TrajectoryInfo] = []
    
    let currentTrajectory = userTrajectory
    var closestIndex = 0
    var startIndex = currentTrajectory.count-15
    for i in 0..<currentTrajectory.count {
        let currentIndex = currentTrajectory[i].index
        let diffIndex = abs(currentIndex - index)
        let compareIndex = abs(closestIndex - index)
        
        if (diffIndex < compareIndex) {
            closestIndex = currentIndex
            startIndex = i
        }
    }
    
    for i in startIndex..<currentTrajectory.count {
        result.append(currentTrajectory[i])
    }
    
    return result
}

public func getTrajectoryFromLast(from userTrajectory: [TrajectoryInfo], N: Int) -> [TrajectoryInfo] {
    let size = userTrajectory.count
    guard size >= N else {
        return userTrajectory
    }
    
    let startIndex = size - N
    let endIndex = size
    
    var result: [TrajectoryInfo] = []
    for i in startIndex..<endIndex {
        result.append(userTrajectory[i])
    }

    return result
}

public func getTrajectoryForDiagonal(from userTrajectory: [TrajectoryInfo], N: Int) -> [TrajectoryInfo] {
    let size = userTrajectory.count
    guard size >= N else {
        return userTrajectory
    }
    
    let startIndex = N
    let endIndex = size
    
    var result: [TrajectoryInfo] = []
    for i in startIndex..<endIndex {
        result.append(userTrajectory[i])
    }

    return result
}

public func cutTrajectoryFromLast(from userTrajectory: [TrajectoryInfo], userLength: Double, cutLength: Double) -> [TrajectoryInfo] {
    let trajLength = userLength
    
    if (trajLength < cutLength) {
        return userTrajectory
    } else {
        var cutIndex = 0
        
        var accumulatedLength: Double = 0
        for i in (0..<userTrajectory.count).reversed() {
            accumulatedLength += userTrajectory[i].length
            
            if (accumulatedLength > cutLength) {
                cutIndex = i
                break
            }
        }
        
        let startIndex = userTrajectory.count - cutIndex
        let endIndex = userTrajectory.count

        var result: [TrajectoryInfo] = []
        for i in startIndex..<endIndex {
            result.append(userTrajectory[i])
        }
        
        return result
    }
}

public func getSearchCoordinates(areaMinMax: [Double], interval: Double) -> [[Double]] {
    var coordinates: [[Double]] = []
    
    let xMin = areaMinMax[0]
    let yMin = areaMinMax[1]
    let xMax = areaMinMax[2]
    let yMax = areaMinMax[3]
    
    var x = xMin
        while x <= xMax {
            coordinates.append([x, yMin])
            coordinates.append([x, yMax])
            x += interval
        }
        
        var y = yMin
        while y <= yMax {
            coordinates.append([xMin, y])
            coordinates.append([xMax, y])
            y += interval
        }
    
    return coordinates
}

public func convertToValidSearchRange(inputRange: [Int], pathPointMinMax: [Double]) -> [Int] {
    var searchRange = inputRange
    
    let minMax: [Int] = pathPointMinMax.map { Int($0) }
    if (pathPointMinMax.isEmpty) {
        return searchRange
    }
    if (pathPointMinMax[0] == 0 && pathPointMinMax[1] == 0 && pathPointMinMax[2] == 0 && pathPointMinMax[3] == 0) {
        return searchRange
    }
    
    // Check isValid
    if (inputRange[0] < minMax[0]) {
        let diffX = minMax[0] - inputRange[0]
        searchRange[0] = minMax[0]
        
        searchRange[2] = inputRange[2] + Int(Double(diffX)*0.5)
        if (searchRange[2] > minMax[2]) {
            searchRange[2] = minMax[2]
        }
    }
    
    if (inputRange[1] < minMax[1]) {
        let diffY = minMax[1] - inputRange[1]
        searchRange[1] = minMax[1]
        
        searchRange[3] = inputRange[3] + Int(Double(diffY)*0.5)
        if (searchRange[3] > minMax[3]) {
            searchRange[3] = minMax[3]
        }
    }
    
    if (inputRange[2] > minMax[2]) {
        let diffX = inputRange[2] - minMax[2]
        searchRange[2] = minMax[2]
        
        searchRange[0] = inputRange[0] - Int(Double(diffX)*0.5)
        if (searchRange[0] < minMax[0]) {
            searchRange[0] = minMax[0]
        }
    }
    
    if (inputRange[3] > minMax[3]) {
        let diffY = inputRange[3] - minMax[3]
        searchRange[3] = minMax[3]
        
        searchRange[1] = inputRange[1] - Int(Double(diffY)*0.5)
        if (searchRange[1] < minMax[1]) {
            searchRange[1] = minMax[1]
        }
    }
    
//    print("Search Range : input = \(inputRange) , minMax = \(pathPointMinMax) , result = \(searchRange)")
    
    return searchRange
}

public func extractSectionWithLeastChange(inputArray: [Double]) -> [Double] {
    guard inputArray.count > 7 else {
        return []
    }

    var bestSliceStartIndex = 0
    var bestSliceEndIndex = 0

    for startIndex in 0..<(inputArray.count-6) {
        for endIndex in (startIndex+7)..<inputArray.count {
            let slice = Array(inputArray[startIndex...endIndex])
            guard let minSliceValue = slice.min(), let maxSliceValue = slice.max() else {
                continue
            }

            let currentDifference = abs(maxSliceValue - minSliceValue)
            if currentDifference < 5 && slice.count > bestSliceEndIndex - bestSliceStartIndex {
                bestSliceStartIndex = startIndex
                bestSliceEndIndex = endIndex
            }
        }
    }

    return Array(inputArray[bestSliceStartIndex...bestSliceEndIndex])
}

public func selectBestScResult(inputPhase: Int, inputDirections: [Double], inputList: FineLocationTrackingListFromServer) -> FineLocationTrackingFromServer {
    var result = FineLocationTrackingFromServer()
    
    var bestIdx: Int = 0
    var bestScc: Double = 0
    
    var numClusters: Int = 2
    var headingCluster = [Double]()
    
    var scResults = [[Double]]()
    for idx in 0..<inputList.flt_outputs.count {
        let eachResult = inputList.flt_outputs[idx]
        let eachResultX: Double = eachResult.x
        let eachResultY: Double = eachResult.y
        let eachResultScc: Double = eachResult.scc
        let eachResultHeading: Double = eachResult.absolute_heading
        
        scResults.append([eachResultX, eachResultY, eachResultHeading, eachResultScc, Double(idx)])
        if eachResultScc > bestScc {
            bestScc = eachResultScc
            bestIdx = idx
        }
        
        if (inputPhase < 4) {
            if (inputDirections.isEmpty) {
                return inputList.flt_outputs[bestIdx]
            }
            
            // Heading 을 이용한 Cluster 갯수 설정
            let closestHeading = findClosestValue(to: eachResult.absolute_heading, in: inputDirections)
            headingCluster.append(closestHeading)
        }
    }
    
    let bestResult = inputList.flt_outputs[bestIdx]
    
    if (inputPhase == 4 && bestResult.phase < 4) {
        return bestResult
    } else {
        if (inputPhase < 4) {
            let uniqueHeadings = Array(Set(headingCluster))
            numClusters = uniqueHeadings.count
//            print(getLocalTimeString() + " , (Jupiter) Cluster : input = \(inputDirections) // Headings = \(uniqueHeadings) // num = \(numClusters)")
            
            if (numClusters == 1) {
                numClusters = 2
            }
        }
        
        let clusterLabels = kmeansClustering(data: scResults, numClusters: numClusters, phase: inputPhase)
        if (clusterLabels.0) {
//            print(getLocalTimeString() + " , (Jupiter) Cluster : Labels = \(clusterLabels.1)")
            let classifiedData = classifyData(data: scResults, labels: clusterLabels.1)
//            print(getLocalTimeString() + " , (Jupiter) Cluster : Data = \(classifiedData)")
            
            if let largestValue = findKeyWithLargestValue(classifiedData) {
                var ratio: Double = Double((largestValue.1)/scResults.count)
                
                if (ratio >= 0.5) {
                    if let clusteredScResult = classifiedData[largestValue.0] {
                        var bestScIdx: Int = 0
                        var bestScScc: Double = 0
                        for i in 0..<clusteredScResult.count {
                            if clusteredScResult[i][3] > bestScScc {
                                bestScScc = clusteredScResult[i][3]
                                bestScIdx = i
                            }
                        }
                        result = inputList.flt_outputs[bestScIdx]
//                        print(getLocalTimeString() + " , (Jupiter) Cluster : ClusteredResult = \(result)")
                        return result
                    }
                } else {
                    
                }
            }
        }
    }
    
    result = inputList.flt_outputs[bestIdx]
    
    return result
}

func findClosestValue(to A: Double, in B: [Double]) -> Double {
    var closestValue = B[0]
    var minDifference = abs(B[0] - A)
    
    for value in B {
        let difference = abs(value - A)
        if difference < minDifference {
            minDifference = difference
            closestValue = value
        }
    }
    
    return closestValue
}

func findKeyWithLargestValue(_ dictionary: [String: [[Double]]]) -> (String, Int)? {
    var largestCount = 0
    var keyWithLargestValue: String?

    for (key, value) in dictionary {
        let count = value.count
        if count > largestCount {
            largestCount = count
            keyWithLargestValue = key
        }
    }

    if let key = keyWithLargestValue {
        return (key, largestCount)
    } else {
        return nil
    }
}

public func calculateDistanceXy(point1: [Double], point2: [Double], weights: [Double]) -> Double {
    let squaredDist = weights[0...1].enumerated().reduce(0.0) { (result, arg) in
        let (index, weight) = arg
        let diff = point1[index] - point2[index]
        return result + weight * diff * diff
    }
    return sqrt(squaredDist)
}

public func calculateDistance(point1: [Double], point2: [Double], weights: [Double]) -> Double {
    let squaredDist = weights[0...2].enumerated().reduce(0.0) { (result, arg) in
        let (index, weight) = arg
        let diff = point1[index] - point2[index]
        return result + weight * diff * diff
    }
    return sqrt(squaredDist)
}

public func kmeansClustering(data: [[Double]], numClusters: Int, maxIterations: Int = 100, phase: Int) -> (Bool, [Int]) {
    var isSuccess: Bool = true
    var originalArray: [[Double]] = data
    
    var newArray: [[Double]] = []
    for row in originalArray {
        newArray.append(Array(row.prefix(3)))
    }
    
    let numFeatures = newArray[0].count

    var centroids = Array(newArray.prefix(numClusters))

    let weights: [Double] = [1.0, 1.0, 1.0]
    
    var labels = [Int]()
    for _ in 0..<maxIterations {
        labels = [Int]()
        for point in data {
            var distances = [Double]()
            for centroid in centroids {
                if (phase < 4) {
                    let distance = calculateDistance(point1: point, point2: centroid, weights: weights)
                    distances.append(distance)
                    if (distance.isNaN) {
                        return (false, labels)
                    }
                } else {
                    let distance = calculateDistanceXy(point1: point, point2: centroid, weights: weights)
                    distances.append(distance)
                    if (distance.isNaN) {
                        return (false, labels)
                    }
                }
            }

            let clusterLabel = distances.firstIndex(of: distances.min()!)!
            labels.append(clusterLabel)
        }

        var newCentroids = [[Double]]()

        for i in 0..<numClusters {
            let clusterData = data.enumerated().filter { labels[$0.offset] == i }.map { $0.element }
            let clusterCentroid = (0..<numFeatures).map { featureIndex in
                clusterData.reduce(0.0) { $0 + $1[featureIndex] } / Double(clusterData.count)
            }
            newCentroids.append(clusterCentroid)
        }

        if centroids.elementsEqual(newCentroids, by: { $0.elementsEqual($1) }) {
            break
        }

        centroids = newCentroids
    }

    return (isSuccess, labels)
}

public func classifyData(data: [[Double]], labels: [Int]) -> [String :[[Double]]] {
    var result = [String: [[Double]]]()
    for i in 0..<labels.count {
        let dataLabel: String = String(labels[i])
        
        if let value = result[dataLabel] {
            var newValue = value
            newValue.append(data[i])
            result[dataLabel] = newValue
        } else {
            result[dataLabel] = [data[i]]
        }
    }
    
    return result
}

public func checkIsNeedSkipResult(serverResult: FineLocationTrackingFromServer, currentResult: FineLocationTrackingResult, mode: String, isResultSkipped: Bool) -> Bool {
    var isNeedSkip: Bool = false
    if (isResultSkipped) {
//        print(getLocalTimeString() + " , (Jupiter) Skip : isSkippedResult = \(isResultSkipped)")
        return isNeedSkip
    }
    var unitLength: Double = 1.0
    
    if (currentResult.mobile_time == 0) {
        return isNeedSkip
    }
    
    var dx: Double = 0
    var dy: Double = 0
    
    if (mode == "pdr") {
        unitLength = 0.6
        let currentIndex = currentResult.index
        let diffIndex = currentIndex - serverResult.index
        if (diffIndex < 0) {
            return isNeedSkip
        } else {
            dx = abs(serverResult.x - currentResult.x)
            dy = abs(serverResult.y - currentResult.y)
            let dist = sqrt(dx*dx + dy*dy)
            
            let DIST_THRESHOLD: Double = unitLength*Double(diffIndex+5)
            if (dist > DIST_THRESHOLD) {
                isNeedSkip = true
//                print(getLocalTimeString() + " , (Jupiter) Skip : isNeedSkip = \(isNeedSkip) // TH = \(DIST_THRESHOLD) // dist = \(dist)")
                return isNeedSkip
            }
        }
    } else {
        unitLength = 1.05
    }
    
    
    return isNeedSkip
}

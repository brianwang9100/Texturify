//
//  ARCore.swift
//  Texturify
//
//  Created by Brian Wang on 9/16/17.
//  Copyright © 2017 BW. All rights reserved.
//

import Foundation
import SceneKit
import UIKit
import ARKit

extension SCNVector3: Equatable {
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    func distance(from vector: SCNVector3) -> Float {
        let distanceX = self.x - vector.x
        let distanceY = self.y - vector.y
        let distanceZ = self.z - vector.z
        
        return sqrtf( (distanceX * distanceX) + (distanceY * distanceY) + (distanceZ * distanceZ))
    }
    
    public static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return (lhs.x == rhs.x) && (lhs.y == rhs.y) && (lhs.z == rhs.z)
    }
    
    public static func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    public static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    public static func / (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3(lhs.x/rhs, lhs.y/rhs, lhs.z/rhs)
    }
}

extension ARSCNView {
    func realWorldVector(screenPosition: CGPoint) -> SCNVector3? {
        let planeTestResults = self.hitTest(screenPosition, types: [.featurePoint])
        if let result = planeTestResults.first {
            return SCNVector3.positionFromTransform(result.worldTransform)
        }
        
        return nil
    }
}

extension SCNNode {
    func removeAllChildren() {
        for node in self.childNodes {
            node.removeFromParentNode()
        }
    }
}

extension SCNGeometry {
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    class func planeFrom(points:[SCNVector3]) -> SCNGeometry? {
        if points.count == 4 {
            var finalPoints:[SCNVector3] = []
            var minY:Float!
            for i in 0...3 {
                let point = points[i]
                if minY == nil || point.y < minY {
                    minY = point.y
                }
            }
            for i in 0...3 {
                let point = points[i]
                finalPoints.append(SCNVector3(point.x, minY, point.z))
            }
            
            var indices: [CInt] = [0, 1, 2]
            let lastPoint = finalPoints[3]
            var closestDistancePoints = finalPoints.sorted(by: { left, right in
                lastPoint.distance(from: left) < lastPoint.distance(from: right)
            })
            let firstIndex = CInt(finalPoints.index(of: closestDistancePoints[1])!)
            let secondIndex = CInt(finalPoints.index(of: closestDistancePoints[2])!)
            indices.append(firstIndex)
            indices.append(secondIndex)
            indices.append(3)
            
            let source = SCNGeometrySource(vertices: finalPoints)
            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
            
            return SCNGeometry(sources: [source], elements: [element])
        }
        return nil
    }
}

extension SCNMaterial {
    static var cachedMaterials:[String:SCNMaterial] = [:]
    static func materialNamed(name:String) -> SCNMaterial {
        if let m = cachedMaterials[name] {
            return m
        }
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIImage(named: "./art.scnassets/\(name)/\(name)-albedo.png")
        material.roughness.contents = UIImage(named: "./art.scnassets/\(name)/\(name)-roughness.png")
        material.metalness.contents = UIImage(named: "./art.scnassets/\(name)/\(name)-metal.png")
        material.normal.contents = UIImage(named: "./art.scnassets/\(name)/\(name)-normal.png")
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.roughness.wrapS = .repeat
        material.roughness.wrapT = .repeat
        material.metalness.wrapS = .repeat
        material.metalness.wrapT = .repeat
        material.normal.wrapS = .repeat
        material.normal.wrapT = .repeat
        
        cachedMaterials[name] = material
        return material
    }
}

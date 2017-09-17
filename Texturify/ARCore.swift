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
    
    func highlightedNode(screenPosition: CGPoint, ignore: [SCNNode]) -> SCNNode? {
        let results = self.hitTest(screenPosition, options: nil)
        for result in results {
            if !ignore.contains(result.node) {
                return result.node
            }
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
    
    func changeMaterialToColor(color:UIColor) {
        let material = SCNMaterial()
        material.diffuse.contents = color
        self.geometry?.materials = [material]
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
        if points.count > 2 {
            //VERTICES
            var finalPoints:[SCNVector3] = []
            var minY:Float!
            for i in 0..<points.count {
                let point = points[i]
                if minY == nil || point.y < minY {
                    minY = point.y
                }
            }
            for i in 0..<points.count {
                let point = points[i]
                finalPoints.append(SCNVector3(point.x, minY, point.z))
            }
            let length = finalPoints.count
            let centroid = SCNVector3Make(
                finalPoints.map({ $0.x }).reduce(0, +) / Float(length),
                finalPoints.map({ $0.y }).reduce(0, +) / Float(length),
                finalPoints.map({ $0.z }).reduce(0, +) / Float(length)
            )
            
            finalPoints = finalPoints.sorted(by: { atan2(Double($0.z - centroid.z), Double($0.x - centroid.x)) < atan2(Double($1.z - centroid.z), Double($1.x - centroid.x)) })
            finalPoints.append(centroid)
            var indices: [CInt] = []
            let last = finalPoints.count - 1;
            for i in 0..<last { //last one is centroid
                if (i == last - 1) {
                    indices.append(CInt(i))
                    indices.append(CInt(0))
                    indices.append(CInt(last))
                } else {
                    indices.append(CInt(i))
                    indices.append(CInt(i+1))
                    indices.append(CInt(last))
                }
                
            }
            let source = SCNGeometrySource(vertices: finalPoints)
            
            // NORMALS
            var normals:[SCNVector3] = []
            for _ in finalPoints {
                normals.append(SCNVector3(0,1,0))
            }
            let normalSource = SCNGeometrySource(normals: normals)
            
            //TEXTURE COORDS
            var coords:[CGPoint] = []
            for point in finalPoints {
                coords.append(CGPoint(x: CGFloat(point.x), y: CGFloat(point.z)))
            }
            let textureCoordSource = SCNGeometrySource(textureCoordinates: coords)
            
            //ELEMENTS
            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
            
            return SCNGeometry(sources: [source, normalSource, textureCoordSource], elements: [element])
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

import AppKit
import Combine
import Metal
import QuartzCore
import SceneKit
import SwiftUI

/// Vertex as a small 3D model, in whichever of its four looks is chosen (see `Look`). All four
/// share one skeleton (a body that is carried, turned and leaned, a head on a neck, optional arms
/// and legs), one face (eyes, eyebrows, cheeks) and one lighting set-up, so every behaviour and
/// every expression works on each of them. `show` poses the model for one frame.
///
/// One unit in the scene is one point on screen. The ground is y = 0 and the buddy faces +z.
@MainActor
final class Robot3D {
    let look: Look
    let scene = SCNScene()
    let cameraNode = SCNNode()

    private struct EyeNodes {
        let holder = SCNNode(), block = SCNNode(), arc = SCNNode(), glow = SCNNode()
        let brow = SCNNode(), cheek = SCNNode(), glint = SCNNode()
    }

    /// The measurements that differ from look to look.
    private struct Build {
        /// Height of the neck above the ground when standing.
        var neck: CGFloat = 32
        var hasLegs = true
        /// Half the distance between the feet, where a leg joins the body (right side), ankle height.
        var stance: CGFloat = 11
        var hip = SCNVector3(9.5, -19, 0)
        var ankle: CGFloat = 6
        /// How much of a head tilt the body takes; the head takes the rest.
        var bodyRoll: CGFloat = 0.3
        /// Flat art cannot turn or nod, only tilt.
        var flat = false
        var shadow = CGSize(width: 112, height: 74)
        var pool = CGSize(width: 140, height: 88)
        // The face: size of the area the eyes may use, eye size and spacing, where things sit.
        var glass = CGSize(width: 50, height: 38)
        var eyeScale: CGFloat = 1.1
        var eyeGap: CGFloat = 12.5
        var eyeDrop: CGFloat = 1
        var cheek = CGPoint(x: 6.5, y: -10.5)
        /// Eyes that glow on a dark screen, or dark eyes drawn on a pale body.
        var glowing = true
        /// How strong the soft halo round a glowing eye is.
        var halo: CGFloat = 0.55
        var minBlush: CGFloat = 0
    }

    private var build = Build()
    /// Carries the buddy about and turns it to face the way it walks.
    private let mover = SCNNode()
    /// Leans and rolls; everything above the legs hangs off it. Its origin is the neck.
    private let body = SCNNode()
    private let neck = SCNNode()
    private let face = SCNNode()
    private let arms = [SCNNode(), SCNNode()]
    private let feet = [SCNNode(), SCNNode()]
    private let legs = [SCNNode(), SCNNode()]
    private let shadow = SCNNode()
    private let floorGlow = SCNNode()
    private let underLight = SCNLight()
    private let eyes = [EyeNodes(), EyeNodes()]

    /// The eyes and eyebrows.
    private let lit = Robot3D.flat(.white)
    private let glowMaterial = Robot3D.flat(.white)
    private let floorMaterial = Robot3D.pool()
    private let shadowMaterial = Robot3D.pool()
    /// Headphones and other trim; the parts that glow in the trim colour; the cloud's body.
    private let phones = Robot3D.plastic(0x39F06A, rough: 0.28)
    private let band = Robot3D.plastic(0x39F06A, rough: 0.4)
    private let neon = Robot3D.flat(.white)
    private let skin = Robot3D.plastic(0xB0C6FF, rough: 0.62)
    /// The two parts of the pixel head that change colour.
    private let pixelTrim = Robot3D.flat(.white)
    private let pixelRing = Robot3D.flat(.white)
    private var shapes: [String: SCNGeometry] = [:]
    private var eyeKeys = ["", ""]
    private var last: MascotFrame?

    init(_ look: Look) {
        self.look = look
        scene.background.contents = NSColor.clear
        scene.lightingEnvironment.contents = Self.studio
        scene.lightingEnvironment.intensity = 1.1
        buildCameraAndLights()
        scene.rootNode.addChildNode(mover)
        mover.addChildNode(body)
        switch look {
        case .cloud: buildCloud()
        case .pixel: buildPixel()
        case .robo: buildRobo()
        case .cozy: buildCozy()
        }
        if build.hasLegs {
            for i in 0..<2 {
                scene.rootNode.addChildNode(legs[i])
                scene.rootNode.addChildNode(feet[i])
            }
        }
        buildFace()
    }

    // MARK: Materials and textures

    private static func plastic(_ hex: UInt32, rough: CGFloat, metal: CGFloat = 0) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = RGB(hex: hex).ns()
        m.roughness.contents = NSNumber(value: Double(rough))
        m.metalness.contents = NSNumber(value: Double(metal))
        return m
    }

    /// Soft matte cloth. Light catches the edges that turn away from you, as it does on fleece.
    private static func fabric(_ hex: UInt32 = 0x1B1C20) -> SCNMaterial {
        let m = plastic(hex, rough: 0.94)
        m.shaderModifiers = [.surface: """
        #pragma body
        float fuzz = 1.0 - clamp(dot(normalize(_surface.view), normalize(_surface.normal)), 0.0, 1.0);
        _surface.diffuse.rgb += float3(0.085, 0.09, 0.11) * pow(fuzz, 2.4);
        """]
        return m
    }

    /// An unlit colour, for the parts that glow and for flat art.
    private static func flat(_ color: NSColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = color
        return m
    }

    private static func flat(_ hex: UInt32) -> SCNMaterial { flat(RGB(hex: hex).ns()) }

    /// A see-through patch on the floor: the soft blob, in one colour, at a strength set each frame.
    ///
    /// The window is see-through and stores colour gamma-encoded. Left alone, the renderer encodes
    /// a faint colour far brighter than its transparency allows, so the soft rim of a patch shows
    /// up as a pale ring on a light desktop. This works out the colour the desktop should receive
    /// (tint times how solid the patch is) and hands the renderer exactly what encodes to that.
    private static func pool() -> SCNMaterial {
        let m = flat(.white)
        m.diffuse.contents = blob(.white)
        m.writesToDepthBuffer = false
        m.shaderModifiers = [.fragment: """
        #pragma arguments
        float3 tint;
        float strength;
        #pragma transparent
        #pragma body
        float solid = _output.color.a * strength;
        float3 shown = tint * solid;
        float3 light = mix(shown / 12.92, pow((shown + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), shown));
        _output.color = float4(light, solid);
        """]
        m.setValue(NSValue(scnVector3: SCNVector3(0, 0, 0)), forKey: "tint")
        m.setValue(NSNumber(value: 1.0), forKey: "strength")
        return m
    }

    private static func bitmap(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> CGImage? {
        guard let g = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        draw(g)
        return g.makeImage()
    }

    private static func gradient(_ stops: [(CGFloat, NSColor)]) -> CGGradient {
        CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: stops.map { $0.1.cgColor } as CFArray,
                   locations: stops.map { $0.0 })!
    }

    /// What the shiny parts reflect: a bright ceiling, a grey horizon, a dark floor, and two
    /// soft light panels, like a small photo studio.
    private static let studio: CGImage? = bitmap(512, 256) { g in
        let sky = gradient([(0, NSColor(white: 0.1, alpha: 1)), (0.45, NSColor(white: 0.42, alpha: 1)),
                            (0.75, NSColor(white: 0.8, alpha: 1)), (1, NSColor(white: 1, alpha: 1))])
        g.drawLinearGradient(sky, start: .zero, end: CGPoint(x: 0, y: 256), options: [])
        let panel = gradient([(0, NSColor(white: 1, alpha: 0.95)), (1, NSColor(white: 1, alpha: 0))])
        for x in [110.0, 380.0] {
            g.saveGState()
            g.translateBy(x: x, y: 190)
            g.scaleBy(x: 2.2, y: 1)
            g.drawRadialGradient(panel, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 46, options: [])
            g.restoreGState()
        }
    }

    /// A soft round blob: white for glows, black for the shadow. It thins out more and more
    /// gently toward the rim and is fully see-through well before it, so it melts into whatever
    /// is behind it with no visible edge.
    private static func blob(_ color: NSColor) -> CGImage? {
        bitmap(256, 256) { g in
            let stops: [(CGFloat, NSColor)] = (0...24).map { i in
                let r = CGFloat(i) / 24
                let strength = pow(1 - r * r, 2.6)
                return (r, color.withAlphaComponent(color.alphaComponent * strength))
            }
            g.drawRadialGradient(gradient(stops), startCenter: CGPoint(x: 128, y: 128), startRadius: 0,
                                 endCenter: CGPoint(x: 128, y: 128), endRadius: 122, options: [])
        }
    }

    /// A rounded slab standing up to face the camera, `depth` thick.
    private static func slab(_ w: CGFloat, _ h: CGFloat, radius: CGFloat, depth: CGFloat, soften: CGFloat = 0,
                             _ m: SCNMaterial) -> SCNNode {
        let path = NSBezierPath(roundedRect: NSRect(x: -w / 2, y: -h / 2, width: w, height: h), xRadius: radius, yRadius: radius)
        path.flatness = 0.05
        let s = SCNShape(path: path, extrusionDepth: depth)
        s.chamferRadius = min(soften, depth / 2)
        s.materials = [m]
        return SCNNode(geometry: s)
    }

    private static func box(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, round: CGFloat, _ m: SCNMaterial) -> SCNNode {
        let b = SCNBox(width: w, height: h, length: d, chamferRadius: round)
        b.chamferSegmentCount = max(4, Int(round * 0.75))
        b.materials = [m]
        return SCNNode(geometry: b)
    }

    private static func ball(_ r: CGFloat, _ m: SCNMaterial) -> SCNNode {
        let s = SCNSphere(radius: r)
        s.segmentCount = 40
        s.materials = [m]
        return SCNNode(geometry: s)
    }

    /// A headphone band: an arch that runs up one side of the head, over the top and down the other.
    private static func arch(half: CGFloat, top: CGFloat, corner: CGFloat, thick: CGFloat, deep: CGFloat,
                             from: CGFloat = 0, _ m: SCNMaterial) -> SCNNode {
        let line = CGMutablePath()
        line.move(to: CGPoint(x: -half, y: from))
        line.addArc(tangent1End: CGPoint(x: -half, y: top), tangent2End: CGPoint(x: 0, y: top), radius: corner)
        line.addArc(tangent1End: CGPoint(x: half, y: top), tangent2End: CGPoint(x: half, y: from), radius: corner)
        line.addLine(to: CGPoint(x: half, y: from))
        let path = NSBezierPath(cgPath: line.copy(strokingWithWidth: thick, lineCap: .butt, lineJoin: .round, miterLimit: 4))
        path.flatness = 0.05
        let s = SCNShape(path: path, extrusionDepth: deep)
        s.chamferRadius = min(1.3, thick / 2.5)
        s.materials = [m]
        return SCNNode(geometry: s)
    }

    /// The faint streak of light across a glass screen, in front of the eyes.
    private static func sheen(_ w: CGFloat, _ h: CGFloat, corner: CGFloat) -> SCNNode {
        let plane = SCNPlane(width: w, height: h)
        plane.cornerRadius = corner
        let m = flat(.white)
        m.diffuse.contents = bitmap(256, 180) { g in
            let streak = gradient([(0, NSColor(white: 1, alpha: 0)), (0.3, NSColor(white: 1, alpha: 0.07)),
                                   (0.42, NSColor(white: 1, alpha: 0.014)), (1, NSColor(white: 1, alpha: 0))])
            g.drawLinearGradient(streak, start: CGPoint(x: 20, y: 180), end: CGPoint(x: 170, y: 25), options: [])
        }
        m.writesToDepthBuffer = false
        m.blendMode = .add
        plane.materials = [m]
        let n = SCNNode(geometry: plane)
        n.castsShadow = false
        n.renderingOrder = 10
        return n
    }

    // MARK: Camera, lights and floor

    private func buildCameraAndLights() {
        // A long lens from slightly above, so the buddy has depth without looking distorted.
        let camera = SCNCamera()
        camera.fieldOfView = 12
        camera.zNear = 200
        camera.zFar = 1400
        cameraNode.camera = camera
        let middle = RobotArt.ground - RobotArt.size.height / 2
        let distance = RobotArt.size.height / 2 / tan(6 * .pi / 180)
        let rise: CGFloat = 9 * .pi / 180
        cameraNode.position = SCNVector3(0, middle + distance * sin(rise), distance * cos(rise))
        cameraNode.look(at: SCNVector3(0, middle, 0))
        scene.rootNode.addChildNode(cameraNode)

        func lamp(_ light: SCNLight, from: SCNVector3, at: SCNVector3) {
            let n = SCNNode()
            n.light = light
            n.position = from
            n.look(at: at)
            scene.rootNode.addChildNode(n)
        }
        let key = SCNLight()
        key.type = .directional
        key.intensity = 1050
        key.castsShadow = true
        key.shadowRadius = 6
        key.shadowSampleCount = 16
        key.shadowMapSize = CGSize(width: 1024, height: 1024)
        key.shadowColor = NSColor(white: 0, alpha: 0.5)
        lamp(key, from: SCNVector3(-160, 260, 260), at: SCNVector3(0, 40, 0))

        let rim = SCNLight()
        rim.type = .directional
        rim.intensity = 700
        rim.color = NSColor(srgbRed: 0.82, green: 0.88, blue: 1, alpha: 1)
        lamp(rim, from: SCNVector3(200, 180, -220), at: SCNVector3(0, 50, 0))

        // The glow from the floor, in the status colour, catching the feet and the hem.
        underLight.type = .directional
        underLight.intensity = 260
        lamp(underLight, from: SCNVector3(0, -120, 90), at: SCNVector3(0, 30, 0))

        // A pool of coloured light on the "floor", then the soft dark shadow over it.
        for (node, material, order) in [(floorGlow, floorMaterial, -20), (shadow, shadowMaterial, -10)] {
            let plane = SCNPlane(width: 1, height: 1)
            plane.materials = [material]
            node.geometry = plane
            node.eulerAngles.x = -.pi / 2
            node.renderingOrder = order
            node.castsShadow = false
            scene.rootNode.addChildNode(node)
        }
    }

    // MARK: Cozy Vertex: the hoodie

    private func buildCozy() {
        let cloth = Self.fabric()
        let dark = Self.fabric(0x141518)
        for i in 0..<2 {
            // A soft, rounded shoe with a glowing sole.
            let shoe = Self.box(20, 11, 27, round: 5.4, dark)
            shoe.position = SCNVector3(0, 5.6, 4)
            feet[i].addChildNode(shoe)
            let sole = Self.box(18.5, 2.6, 25.5, round: 1.3, neon)
            sole.position = SCNVector3(0, 1.1, 4)
            sole.castsShadow = false
            feet[i].addChildNode(sole)
            leg(i, radius: 6.2, dark)
        }

        // The hoodie: a chunky rounded block from the neck down to the hem.
        let torso = Self.box(42, 27, 34, round: 12.5, cloth)
        torso.position = SCNVector3(0, -11.5, 0)
        body.addChildNode(torso)
        // Two glowing drawstrings down the chest.
        for x: CGFloat in [-4.2, 4.2] {
            let cord = SCNNode(geometry: SCNCapsule(capRadius: 1.25, height: 12.5))
            cord.geometry?.materials = [neon]
            cord.position = SCNVector3(x, -9.5, 17.2)
            cord.castsShadow = false
            body.addChildNode(cord)
        }
        // Stubby arms that hang from the shoulders: sleeve, glowing cuff, mitten.
        for i in 0..<2 {
            let sleeve = SCNNode(geometry: SCNCapsule(capRadius: 5.6, height: 17))
            sleeve.geometry?.materials = [cloth]
            sleeve.position = SCNVector3(0, -6, 0)
            arms[i].addChildNode(sleeve)
            let cuff = SCNNode(geometry: SCNTorus(ringRadius: 5.3, pipeRadius: 1.0))
            cuff.geometry?.materials = [neon]
            cuff.position = SCNVector3(0, -10.5, 0)
            cuff.castsShadow = false
            arms[i].addChildNode(cuff)
            let mitt = Self.ball(5.9, dark)
            mitt.position = SCNVector3(0, -14.5, 0)
            arms[i].addChildNode(mitt)
            arms[i].position = SCNVector3((i == 0 ? -1 : 1) * 22, -5, 0)
            body.addChildNode(arms[i])
        }
        body.addChildNode(neck)

        // The hood, its padded edge standing a little proud round the face, then the glass.
        let hood = (w: CGFloat(66), h: CGFloat(58), d: CGFloat(56))
        let head = SCNNode()
        head.position = SCNVector3(0, hood.h / 2 - 3, 0)
        neck.addChildNode(head)
        head.addChildNode(Self.box(hood.w, hood.h, hood.d, round: 24, cloth))
        let front = hood.d / 2 + 2.5
        let lip = Self.slab(58, 46, radius: 20, depth: 30, soften: 3.4, Self.fabric(0x212226))
        lip.position = SCNVector3(0, 0, front - 15)
        head.addChildNode(lip)
        let glass = Self.slab(50, 38, radius: 16, depth: 1.6, soften: 0.6, Self.plastic(0x040509, rough: 0.06))
        glass.position = SCNVector3(0, 0, front + 0.3)
        glass.castsShadow = false
        head.addChildNode(glass)
        face.position = SCNVector3(0, 0, front + 1.3)
        head.addChildNode(face)
        let shine = Self.sheen(47, 35, corner: 15)
        shine.position = SCNVector3(0, 0, front + 1.8)
        head.addChildNode(shine)

        // Headphones: a slim band over the hood, and a puffy cup with a glowing ring on each ear.
        head.addChildNode(Self.arch(half: hood.w / 2 + 1.6, top: hood.h / 2 + 1.6, corner: 24.5, thick: 3.2, deep: 9,
                                    from: -2, band))
        for side: CGFloat in [-1, 1] {
            let cup = Self.ball(14, phones)
            cup.scale = SCNVector3(0.5, 1, 1)
            cup.position = SCNVector3(side * (hood.w / 2 + 3), -3, 0)
            head.addChildNode(cup)
            let ring = SCNNode(geometry: SCNTorus(ringRadius: 7.4, pipeRadius: 1.25))
            ring.geometry?.materials = [neon]
            ring.eulerAngles.z = .pi / 2
            ring.position = SCNVector3(side * (hood.w / 2 + 8.4), -3, 0)
            ring.castsShadow = false
            head.addChildNode(ring)
        }
    }

    // MARK: Robo Vertex: the boxy robot

    private func buildRobo() {
        build.neck = 30
        build.stance = 13
        build.hip = SCNVector3(10, -5, 0)
        build.ankle = 7
        build.bodyRoll = 0
        build.shadow = CGSize(width: 108, height: 70)
        build.glass = CGSize(width: 58, height: 34)
        build.eyeScale = 1.2
        build.eyeGap = 14
        build.eyeDrop = 0
        build.cheek = CGPoint(x: 7, y: -9.5)
        let shell = Self.plastic(0x30333F, rough: 0.42)
        let dark = Self.plastic(0x22242D, rough: 0.5)
        for i in 0..<2 {
            let shoe = Self.box(18, 7, 28, round: 3.2, shell)
            shoe.position = SCNVector3(0, 3.5, 5)
            feet[i].addChildNode(shoe)
            let sole = Self.box(18.7, 1.7, 28.7, round: 0.85, neon)
            sole.position = SCNVector3(0, 1.5, 5)
            sole.castsShadow = false
            feet[i].addChildNode(sole)
            let ankle = Self.ball(5, dark)
            ankle.position = SCNVector3(0, 7, 0)
            feet[i].addChildNode(ankle)
            leg(i, radius: 4.3, dark)
        }
        let hip = Self.box(36, 12, 22, round: 5, dark)
        hip.position = SCNVector3(0, -4, 0)
        body.addChildNode(hip)
        body.addChildNode(neck)

        let skull = (w: CGFloat(78), h: CGFloat(52), d: CGFloat(46))
        let head = SCNNode()
        head.position = SCNVector3(0, skull.h / 2, 0)
        neck.addChildNode(head)
        head.addChildNode(Self.box(skull.w, skull.h, skull.d, round: 8.5, shell))
        // A brushed bezel, then the glass.
        let bezel = Self.slab(65, 41, radius: 10.5, depth: 3, soften: 0.6, Self.plastic(0x5B5F72, rough: 0.34, metal: 0.55))
        bezel.position = SCNVector3(0, 1, skull.d / 2 + 0.6)
        head.addChildNode(bezel)
        let glass = Self.slab(58, 34, radius: 7.5, depth: 1.4, soften: 0.6, Self.plastic(0x05060A, rough: 0.07))
        glass.position = SCNVector3(0, 1, skull.d / 2 + 1.9)
        glass.castsShadow = false
        head.addChildNode(glass)
        face.position = SCNVector3(0, 1, skull.d / 2 + 2.75)
        head.addChildNode(face)
        let shine = Self.sheen(55, 31, corner: 6.5)
        shine.position = SCNVector3(0, 1, skull.d / 2 + 3.2)
        head.addChildNode(shine)

        // Headphones: a band that hugs the head, and a cup with a glowing ring over each ear.
        head.addChildNode(Self.arch(half: skull.w / 2 + 3.5, top: skull.h / 2 + 3.5, corner: 14, thick: 3.8, deep: 11, phones))
        for side: CGFloat in [-1, 1] {
            let discs: [(CGFloat, CGFloat, CGFloat, SCNMaterial)] = [(12.5, 9, 3.5, phones), (9.5, 1.5, 8.2, dark)]
            for (radius, height, x, material) in discs {
                let disc = SCNCylinder(radius: radius, height: height)
                disc.radialSegmentCount = 48
                disc.materials = [material]
                let n = SCNNode(geometry: disc)
                n.eulerAngles.z = .pi / 2
                n.position = SCNVector3(side * (skull.w / 2 + x), 0, 0)
                head.addChildNode(n)
            }
            let ring = SCNNode(geometry: SCNTorus(ringRadius: 7.6, pipeRadius: 1.3))
            ring.geometry?.materials = [neon]
            ring.eulerAngles.z = .pi / 2
            ring.position = SCNVector3(side * (skull.w / 2 + 8.6), 0, 0)
            ring.castsShadow = false
            head.addChildNode(ring)
        }
    }

    // MARK: Cloud Vertex: the original, as a soft toy

    private func buildCloud() {
        build.neck = 15
        build.hasLegs = false
        build.bodyRoll = 0
        build.shadow = CGSize(width: 104, height: 62)
        build.pool = CGSize(width: 132, height: 80)
        build.glass = CGSize(width: 56, height: 34)
        build.eyeScale = 0.95
        build.eyeGap = 12
        build.eyeDrop = -1
        build.cheek = CGPoint(x: 8, y: -6.5)
        build.glowing = false
        build.minBlush = 0.8
        body.addChildNode(neck)

        // One big rounded pillow with puffs along the top, at the sides and underneath.
        let puff = SCNNode()
        puff.position = SCNVector3(0, 25, 0)
        neck.addChildNode(puff)
        puff.addChildNode(Self.box(74, 50, 46, round: 23, skin))
        let bumps: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(-20, 18, 0, 16), (2, 24, 0, 19), (22, 17, 0, 14),
                                                             (-33, -3, 0, 14), (33, -3, 0, 14),
                                                             (-17, -19, 0, 11.5), (17, -19, 0, 11.5), (0, -21, 2, 11)]
        for (x, y, z, r) in bumps {
            let b = Self.ball(r, skin)
            b.position = SCNVector3(x, y, z)
            puff.addChildNode(b)
        }
        // Little arms at the sides.
        for i in 0..<2 {
            let nub = SCNNode(geometry: SCNCapsule(capRadius: 5.2, height: 15))
            nub.geometry?.materials = [skin]
            nub.position = SCNVector3(0, -4.5, 0)
            arms[i].addChildNode(nub)
            arms[i].position = SCNVector3((i == 0 ? -1 : 1) * 40, 24, 0)
            neck.addChildNode(arms[i])
        }
        face.position = SCNVector3(0, 3, 23.6)
        puff.addChildNode(face)

        // A small smile under the eyes.
        let line = CGMutablePath()
        line.move(to: CGPoint(x: -3.6, y: 0.9))
        line.addQuadCurve(to: CGPoint(x: 3.6, y: 0.9), control: CGPoint(x: 0, y: -3))
        let path = NSBezierPath(cgPath: line.copy(strokingWithWidth: 2, lineCap: .round, lineJoin: .round, miterLimit: 4))
        path.flatness = 0.04
        let smile = SCNShape(path: path, extrusionDepth: 0.3)
        smile.materials = [lit]
        let mouth = SCNNode(geometry: smile)
        mouth.position = SCNVector3(0, -8.5, 0)
        face.addChildNode(mouth)
    }

    // MARK: Pixel Vertex: flat pixel art

    /// Left half of the pixel head; the right half is its mirror image.
    /// Legend: r rim, g body, d shade, k screen, t headphone trim, a glowing ring.
    private static let pixelHalf: [String] = [
        "......ttttttt",
        "....tttrrrrrr",
        "...ttrrgggggg",
        "..ttrgggggggg",
        "..trggkkkkkkk",
        "..trgkkkkkkkk",
        "rrrrgkkkkkkkk",
        "rttrgkkkkkkkk",
        "ratrgkkkkkkkk",
        "ratrgkkkkkkkk",
        "rttrgkkkkkkkk",
        "rrrrgkkkkkkkk",
        "...rggkkkkkkk",
        "...rggggggggg",
        "....rdddddddd",
        ".....rrrrrrrr",
    ]

    /// The pixel head as a crisp picture, colouring each cell with `ink` (nil leaves it clear).
    private static func pixels(_ ink: (Character) -> NSColor?) -> CGImage? {
        let rows = pixelHalf.map { Array($0 + String($0.reversed())) }
        let cell = 12
        return bitmap(rows[0].count * cell, rows.count * cell) { g in
            g.setShouldAntialias(false)
            for (y, row) in rows.enumerated() {
                for (x, ch) in row.enumerated() {
                    guard let c = ink(ch) else { continue }
                    g.setFillColor(c.cgColor)
                    g.fill(CGRect(x: x * cell, y: (rows.count - 1 - y) * cell, width: cell, height: cell))
                }
            }
        }
    }

    private func buildPixel() {
        // One pixel of the art is this many points.
        let px: CGFloat = 3.9
        build.neck = 6 * px
        build.stance = 4.33 * px
        build.hip = SCNVector3(3.67 * px, -0.4 * px, -0.6)
        build.ankle = 1.5 * px
        build.bodyRoll = 0
        build.flat = true
        build.shadow = CGSize(width: 118, height: 60)
        build.glass = CGSize(width: 16 * px, height: 9 * px)
        build.eyeScale = px / 3
        build.eyeGap = 3.83 * px
        build.eyeDrop = 0
        build.cheek = CGPoint(x: 6, y: -9.5)
        build.halo = 0.3
        let rim = Self.flat(0x565A70), fill = Self.flat(0x2C2E3B), shade = Self.flat(0x1F2029)

        for i in 0..<2 {
            let side: CGFloat = i == 0 ? -1 : 1
            // Foot: an outline, the foot itself, and a glowing sole.
            let plates: [(CGFloat, CGFloat, CGFloat, CGFloat, SCNMaterial, CGFloat)] = [
                (7 * px, 3 * px, 1.4 * px, px, rim, 0), (6 * px, 2 * px, 0.7 * px, px, fill, 0.2),
                (4.7 * px, 0.8 * px, 0.3 * px, 0.45 * px, neon, 0.4),
            ]
            for (w, h, r, y, m, z) in plates {
                let plate = Self.slab(w, h, radius: r, depth: 0.2, m)
                plate.position = SCNVector3(side * 0.5 * px, y, z)
                plate.castsShadow = false
                feet[i].addChildNode(plate)
            }
            // Leg: one unit tall, stretched each frame, with its outline behind it.
            let outline = SCNNode(geometry: SCNBox(width: 4 * px, height: 1, length: 0.2, chamferRadius: 0))
            outline.geometry?.materials = [rim]
            let inner = SCNNode(geometry: SCNBox(width: 3 * px, height: 1, length: 0.2, chamferRadius: 0))
            inner.geometry?.materials = [shade]
            inner.position.z = 0.15
            legs[i].addChildNode(outline)
            legs[i].addChildNode(inner)
        }
        let hips: [(CGFloat, CGFloat, CGFloat, SCNMaterial, CGFloat)] = [
            (11.7 * px, 4 * px, 1.5 * px, rim, -0.4), (10.7 * px, 3 * px, px, shade, -0.25),
        ]
        for (w, h, r, m, z) in hips {
            let hip = Self.slab(w, h, radius: r, depth: 0.2, m)
            hip.position = SCNVector3(0, 0.17 * px, z)
            hip.castsShadow = false
            body.addChildNode(hip)
        }
        body.addChildNode(neck)

        // The head: the fixed colours, then the headphones and the rings, which change colour.
        let head = SCNNode()
        head.position = SCNVector3(0, 8 * px, 0.6)
        neck.addChildNode(head)
        let tones: [Character: UInt32] = ["r": 0x565A70, "g": 0x2C2E3B, "d": 0x1F2029, "k": 0x090A0F]
        let layers: [(CGImage?, SCNMaterial)] = [
            (Self.pixels { ch in tones[ch].map { RGB(hex: $0).ns() } }, Self.flat(.white)),
            (Self.pixels { $0 == "t" ? .white : nil }, pixelTrim),
            (Self.pixels { $0 == "a" ? .white : nil }, pixelRing),
        ]
        for (n, (image, material)) in layers.enumerated() {
            material.diffuse.contents = image
            material.diffuse.magnificationFilter = .nearest
            let plane = SCNPlane(width: 26 * px, height: 16 * px)
            plane.materials = [material]
            let node = SCNNode(geometry: plane)
            node.position.z = CGFloat(n) * 0.1
            node.castsShadow = false
            // Drawn before the face, so the glow of the eyes always lands on top of the screen.
            node.renderingOrder = -5 + n
            head.addChildNode(node)
        }
        face.position = SCNVector3(0, -0.5 * px, 0.6)
        head.addChildNode(face)
    }

    // MARK: Legs and face, shared

    /// A leg that is one unit tall and gets stretched each frame to reach from hip to ankle.
    private func leg(_ i: Int, radius: CGFloat, _ m: SCNMaterial) {
        let shin = SCNCylinder(radius: radius, height: 1)
        shin.radialSegmentCount = 32
        shin.materials = [m]
        legs[i].geometry = shin
    }

    private func buildFace() {
        glowMaterial.diffuse.contents = Self.blob(.white)
        glowMaterial.writesToDepthBuffer = false
        glowMaterial.blendMode = .add
        let cheekMaterial = Self.flat(RGB(hex: build.glowing ? 0xFF7FA8 : 0xFF9DB6).ns())
        let browPath = NSBezierPath(roundedRect: NSRect(x: -5, y: -1.2, width: 10, height: 2.4), xRadius: 1.2, yRadius: 1.2)
        browPath.flatness = 0.05
        let cheekPath = NSBezierPath(roundedRect: NSRect(x: -3.3, y: -1.4, width: 6.6, height: 2.8), xRadius: 1.4, yRadius: 1.4)
        cheekPath.flatness = 0.05

        for e in eyes {
            if build.glowing {
                e.glow.geometry = SCNPlane(width: 1, height: 1)
                e.glow.geometry?.materials = [glowMaterial]
                e.glow.position.z = -0.25
                e.holder.addChildNode(e.glow)
            } else {
                // Dark eyes get a white glint, so they look bright and wet rather than flat.
                let dot = SCNShape(path: NSBezierPath(ovalIn: NSRect(x: -1.3, y: -1.3, width: 2.6, height: 2.6)), extrusionDepth: 0.2)
                dot.materials = [Self.flat(.white)]
                e.glint.geometry = dot
                e.holder.addChildNode(e.glint)
            }
            e.holder.addChildNode(e.block)
            // The curved eye sits a hair in front, so the two never fight while one fades into the other.
            e.arc.position.z = 0.4
            e.holder.addChildNode(e.arc)
            face.addChildNode(e.holder)

            let brow = SCNShape(path: browPath, extrusionDepth: 0.3)
            brow.materials = [lit]
            e.brow.geometry = brow
            face.addChildNode(e.brow)

            let cheek = SCNShape(path: cheekPath, extrusionDepth: 0.3)
            cheek.materials = [cheekMaterial]
            e.cheek.geometry = cheek
            face.addChildNode(e.cheek)
        }
        face.enumerateChildNodes { n, _ in n.castsShadow = false }
    }

    /// The eye as an open block: a rounded rectangle, with its top sliced off when a lid is lowered.
    private func blockShape(w: CGFloat, h: CGFloat, cut: CGFloat) -> SCNGeometry {
        let key = "b\(Int(w * 4))|\(Int(h * 4))|\(Int(cut * 20))"
        if let hit = shapes[key] { return hit }
        let radius = min(3.8, h / 2, w / 2)
        var path = CGPath(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h),
                          cornerWidth: radius, cornerHeight: radius, transform: nil)
        if cut > 0.01 {
            path = path.intersection(CGPath(rect: CGRect(x: -w, y: -h, width: w * 2, height: h * 1.5 - h * cut), transform: nil))
        }
        return remember(key, path)
    }

    /// The eye as a curved line: "^" when happy, "‿" when asleep.
    private func arcShape(w: CGFloat, h: CGFloat, up: Bool) -> SCNGeometry {
        let key = "a\(Int(w * 4))|\(Int(h * 4))|\(up)"
        if let hit = shapes[key] { return hit }
        let s: CGFloat = up ? 1 : -1
        let rise = h * 0.5
        let line = CGMutablePath()
        line.move(to: CGPoint(x: -w / 2 + 1.8, y: -s * rise / 2))
        line.addQuadCurve(to: CGPoint(x: w / 2 - 1.8, y: -s * rise / 2), control: CGPoint(x: 0, y: s * rise * 1.5))
        return remember(key, line.copy(strokingWithWidth: 3.4, lineCap: .round, lineJoin: .round, miterLimit: 4))
    }

    private func remember(_ key: String, _ path: CGPath) -> SCNGeometry {
        if shapes.count > 800 { shapes.removeAll() }
        let bezier = NSBezierPath(cgPath: path)
        bezier.flatness = 0.04
        let shape = SCNShape(path: bezier, extrusionDepth: 0.3)
        shape.materials = [lit]
        shapes[key] = shape
        return shape
    }

    // MARK: Posing

    /// Each look wears the colours its own way.
    private func colour(_ f: MascotFrame) {
        let dim = 0.4 + 0.6 * Double(f.glow)
        let glowing = f.accent.mixed(with: .white, 0.14).scaled(dim)
        glowMaterial.multiply.contents = glowing.ns()
        floorMaterial.setValue(NSValue(scnVector3: SCNVector3(f.accent.r, f.accent.g, f.accent.b)), forKey: "tint")
        underLight.color = f.accent.ns()
        switch look {
        case .cozy:
            // Eyes in the status colour; headphones, cords, cuffs and soles in the trim colour.
            lit.diffuse.contents = glowing.ns()
            phones.diffuse.contents = f.trim.scaled(0.8).ns()
            phones.emission.contents = f.trim.scaled(0.22 * dim).ns()
            band.diffuse.contents = f.trim.scaled(0.5).ns()
            neon.diffuse.contents = f.trim.mixed(with: .white, 0.12).scaled(0.55 + 0.45 * dim).ns()
        case .robo:
            // Everything that lights up is in the status colour; the headphones are a deeper shade of it.
            lit.diffuse.contents = glowing.ns()
            neon.diffuse.contents = glowing.ns()
            phones.diffuse.contents = f.accent.mixed(with: RGB(hex: 0x2C2E3B), 0.42).scaled(0.55 + 0.35 * dim).ns()
            phones.emission.contents = NSColor.black
        case .pixel:
            lit.diffuse.contents = glowing.ns()
            neon.diffuse.contents = glowing.ns()
            pixelRing.multiply.contents = glowing.ns()
            pixelTrim.multiply.contents = f.accent.mixed(with: RGB(hex: 0x2C2E3B), 0.3).scaled(0.6 + 0.4 * dim).ns()
        case .cloud:
            // The whole cloud is a pale tint of the status colour, with dark eyes of the same hue.
            skin.diffuse.contents = f.accent.mixed(with: .white, 0.5).scaled(0.72 + 0.28 * dim).ns()
            lit.diffuse.contents = f.accent.scaled(0.3).mixed(with: RGB(hex: 0x1C1E30), 0.55).ns()
        }
    }

    func show(_ f: MascotFrame) {
        let was = last
        last = f
        let rad = CGFloat.pi / 180
        let b = build

        if was?.accent != f.accent || was?.glow != f.glow || was?.trim != f.trim { colour(f) }

        // The body is carried about and turned by `mover`, and leans and rolls on top of that.
        // Flat art only slides and tilts.
        let neckY = b.neck + f.bodyY
        let turn = b.flat ? 0 : f.turn * rad
        let lean = b.flat ? 0 : f.lean
        mover.position = SCNVector3(f.bodyX, neckY, 0)
        mover.eulerAngles.y = turn
        body.eulerAngles = SCNVector3(lean * rad, 0, -f.tilt * b.bodyRoll * rad)
        neck.eulerAngles = SCNVector3(b.flat ? 0 : (f.pitch - lean * 0.6) * rad, b.flat ? 0 : f.yaw * rad,
                                      -f.tilt * (1 - b.bodyRoll) * rad)
        neck.scale = SCNVector3(f.squash, 2 - f.squash, b.flat ? 1 : f.squash)
        for i in 0..<2 where arms[i].parent != nil {
            let side: CGFloat = i == 0 ? -1 : 1
            let arm = i == 0 ? f.armL : f.armR
            arms[i].eulerAngles = SCNVector3(-arm.swing * rad, 0, side * arm.raise * rad)
        }

        // Feet stay where they are planted while the body moves above them; each leg stretches
        // from its hip to its ankle. Sitting down slides the feet out in front.
        let air = min(f.footL.lift, f.footR.lift)
        if b.hasLegs {
            let sit = b.flat ? 0 : max(0, -f.bodyY)
            for i in 0..<2 {
                let side: CGFloat = i == 0 ? -1 : 1
                let foot = i == 0 ? f.footL : f.footR
                let stance = side * b.stance
                feet[i].position = SCNVector3(stance * cos(turn) + foot.dx + sit * 1.2 * sin(turn), foot.lift,
                                              -stance * sin(turn) + sit * 1.2 * cos(turn))
                // A lifted foot points its toe down a little.
                feet[i].eulerAngles = SCNVector3(b.flat ? 0 : min(0.4, foot.lift * 0.05), turn, 0)

                let h = body.convertPosition(SCNVector3(side * b.hip.x, b.hip.y, b.hip.z), to: nil)
                let p = feet[i].position
                let hip = simd_float3(Float(h.x), Float(h.y), Float(h.z))
                let ankle = simd_float3(Float(p.x), Float(p.y + b.ankle), Float(b.flat ? h.z : p.z))
                let along = hip - ankle
                let length = max(1, simd_length(along))
                legs[i].simdPosition = (hip + ankle) / 2
                legs[i].simdOrientation = simd_quatf(from: simd_float3(0, 1, 0), to: along / length)
                legs[i].simdScale = simd_float3(1, length, 1)
            }
        }

        // The floor shadow shrinks as the buddy leaves the ground and fades when it is picked
        // up; the pool of coloured light does the same.
        let up = b.hasLegs ? air : max(0, f.bodyY)
        shadow.position = SCNVector3(f.bodyX * 0.5, 0.1, 3)
        shadow.scale = SCNVector3(b.shadow.width - up * 2.4, b.shadow.height - up * 1.6, 1)
        shadowMaterial.setValue(NSNumber(value: f.held ? 0.2 : 0.55), forKey: "strength")
        floorGlow.position = SCNVector3(f.bodyX * 0.5, 0.05, 3)
        floorGlow.scale = SCNVector3(b.pool.width - up * 2.2, b.pool.height - up * 1.5, 1)
        floorMaterial.setValue(NSNumber(value: Double((f.held ? 0.15 : 0.6) * (0.5 + 0.5 * f.glow))), forKey: "strength")

        guard was?.eyeL != f.eyeL || was?.eyeR != f.eyeR || was?.browL != f.browL || was?.browR != f.browR
            || was?.gaze != f.gaze || was?.brows != f.brows || was?.blush != f.blush else { return }
        let k = b.eyeScale
        let limitX = b.glass.width / 2, limitY = b.glass.height / 2
        for i in 0..<2 {
            let side: CGFloat = i == 0 ? -1 : 1
            let e = i == 0 ? f.eyeL : f.eyeR
            let brow = i == 0 ? f.browL : f.browR
            let n = eyes[i]
            let w = e.w * k, h = e.h * k
            let x = side * b.eyeGap + f.gaze.x * 0.8
            let y = -f.gaze.y * 0.8 - b.eyeDrop
            let curve = min(1, abs(e.arc))

            n.holder.position = SCNVector3(max(-limitX + w / 2 + 2.5, min(limitX - w / 2 - 2.5, x)), y, 0)
            n.holder.eulerAngles.z = side * e.slant * rad
            let key = "\(e.w)|\(e.h)|\(e.cut)|\(e.arc > 0)|\(curve < 0.98)|\(curve > 0.02)"
            if key != eyeKeys[i] {
                eyeKeys[i] = key
                n.block.geometry = curve < 0.98 ? blockShape(w: w, h: h, cut: e.cut) : nil
                n.arc.geometry = curve > 0.02 ? arcShape(w: w, h: h, up: e.arc > 0) : nil
                n.glow.scale = SCNVector3(w + 12, h * (1 - e.cut * 0.6) + 12, 1)
                n.glow.position.y = -h * e.cut * 0.3
                n.glint.position = SCNVector3(-w * 0.2, h * 0.5 - h * e.cut - 2.4, 0.6)
            }
            n.block.opacity = 1 - curve
            n.arc.opacity = curve
            n.glow.opacity = b.halo
            n.glint.opacity = h * (1 - e.cut) > 5.5 ? 1 - curve : 0

            // Eyebrows sit just above the eye and never leave the face.
            n.brow.position = SCNVector3(x * 0.95, min(limitY - 2.6, y + h / 2 + 3 + brow.lift * k), 0)
            n.brow.eulerAngles.z = side * brow.angle * rad
            n.brow.opacity = f.brows
            n.cheek.position = SCNVector3(x + side * b.cheek.x, b.cheek.y, 0)
            n.cheek.opacity = 0.9 * max(b.minBlush, f.blush)
        }
    }

    // MARK: Still images

    private static var studioShots: [Look: (bot: Robot3D, renderer: SCNRenderer)] = [:]

    /// Renders one frame off screen, for snapshots and the app icon.
    static func image(_ f: MascotFrame, look: Look, scale: CGFloat) -> NSImage? {
        if studioShots[look] == nil {
            let bot = Robot3D(look)
            let renderer = SCNRenderer(device: nil, options: nil)
            renderer.scene = bot.scene
            renderer.pointOfView = bot.cameraNode
            studioShots[look] = (bot, renderer)
        }
        guard let shot = studioShots[look] else { return nil }
        shot.bot.show(f)
        let pixels = CGSize(width: RobotArt.size.width * scale, height: RobotArt.size.height * scale)
        let image = shot.renderer.snapshot(atTime: 0, with: pixels, antialiasingMode: .multisampling4X)
        image.size = RobotArt.size
        return image
    }
}

/// One still frame of the buddy as a SwiftUI view, for snapshots and the app icon.
struct RobotCanvas: View, Equatable {
    let frame: MascotFrame
    var look = Look.cozy
    var scale: CGFloat = 1

    var body: some View {
        Group {
            if let image = Robot3D.image(frame, look: look, scale: 2 * scale) {
                Image(nsImage: image).resizable()
            }
        }
        .frame(width: RobotArt.size.width * scale, height: RobotArt.size.height * scale)
    }
}

/// The live buddy: a see-through Metal layer that the model is rendered into once for each new
/// frame from the engine, and never in between. SwiftUI does no work per frame.
final class RobotView: NSView {
    private var bot: Robot3D
    private let metal = CAMetalLayer()
    private let renderer: SCNRenderer
    private let queue: MTLCommandQueue?
    private var feeds: Set<AnyCancellable> = []
    private var shown = MascotFrame()
    /// Rendered at twice the screen's pixels and scaled down, which smooths the edges.
    private let oversample: CGFloat = 2

    init(box: FrameBox) {
        let device = MTLCreateSystemDefaultDevice()
        renderer = SCNRenderer(device: device, options: nil)
        queue = device?.makeCommandQueue()
        bot = Robot3D(box.look)
        super.init(frame: NSRect(origin: .zero, size: RobotArt.size))
        renderer.scene = bot.scene
        renderer.pointOfView = bot.cameraNode
        metal.device = device
        metal.pixelFormat = .bgra8Unorm_srgb
        metal.isOpaque = false
        // Debug: BUDDY_DUMP=<file.png> saves what is really on screen after four seconds.
        metal.framebufferOnly = ProcessInfo.processInfo.environment["BUDDY_DUMP"] == nil
        layer = metal
        wantsLayer = true
        box.frames.sink { [weak self] f in
            self?.shown = f
            self?.bot.show(f)
            self?.render()
        }.store(in: &feeds)
        // A different look is a different model: build it, pose it the same way, and carry on.
        box.$look.dropFirst().sink { [weak self] look in
            guard let self, look != self.bot.look else { return }
            self.bot = Robot3D(look)
            self.renderer.scene = self.bot.scene
            self.renderer.pointOfView = self.bot.cameraNode
            self.bot.show(self.shown)
            self.render()
        }.store(in: &feeds)
        if let path = ProcessInfo.processInfo.environment["BUDDY_DUMP"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in self?.dump(to: path) }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        render()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        render()
    }

    private var lastTexture: MTLTexture?

    private func render() {
        guard window != nil, let queue else { return }
        let scale = (window?.backingScaleFactor ?? 2) * oversample
        let size = CGSize(width: (bounds.width * scale).rounded(), height: (bounds.height * scale).rounded())
        guard size.width > 0, size.height > 0 else { return }
        if metal.drawableSize != size { metal.drawableSize = size }
        guard let drawable = metal.nextDrawable(), let commands = queue.makeCommandBuffer() else { return }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        pass.colorAttachments[0].storeAction = .store
        renderer.render(atTime: 0, viewport: CGRect(origin: .zero, size: size), commandBuffer: commands, passDescriptor: pass)
        commands.present(drawable)
        commands.commit()
        lastTexture = drawable.texture
    }

    private func dump(to path: String) {
        guard let t = lastTexture else { print("dump: nothing rendered"); return }
        var bytes = [UInt8](repeating: 0, count: t.width * t.height * 4)
        t.getBytes(&bytes, bytesPerRow: t.width * 4, from: MTLRegionMake2D(0, 0, t.width, t.height), mipmapLevel: 0)
        let info = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(data: &bytes, width: t.width, height: t.height, bitsPerComponent: 8, bytesPerRow: t.width * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info),
              let image = ctx.makeImage() else { return }
        let rep = NSBitmapImageRep(cgImage: image)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
        print("dump: \(t.width)x\(t.height) written")
    }
}

struct LiveRobot: NSViewRepresentable {
    let box: FrameBox

    func makeNSView(context: Context) -> RobotView { RobotView(box: box) }
    func updateNSView(_ v: RobotView, context: Context) {}
}

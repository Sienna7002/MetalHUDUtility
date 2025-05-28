import SwiftUI
import MetalKit

struct DemoView: View {
    var body: some View {
        MetalViewRepresentable()
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                if UserDefaults.standard.bool(forKey: "MetalForceHudEnabled") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let process = Process()
                        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                        process.arguments = ["-c", "defaults write -g MetalForceHudEnabled -bool YES"]
                        try? process.run()
                    }
                }
            }
    }
}

struct MetalViewRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        // Assign the device, which is a representation of the GPU
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        mtkView.device = defaultDevice
        mtkView.delegate = context.coordinator
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.clearColor = MTLClearColor(red: 0.3, green: 0.0, blue: 0.5, alpha: 1.0)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 1000;

        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
    }

    func makeCoordinator() -> Renderer {
        guard let coordinator = Renderer(device: MTLCreateSystemDefaultDevice()!) else {
            fatalError("Failed to create Renderer")
        }
        return coordinator
    }
}

struct CubeVertex {
    var position: SIMD3<Float>
    var texCoord: SIMD2<Float>
}

struct QuadVertex {
    var position: SIMD2<Float>
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    // Pipeline states
    var gradientPipelineState: MTLRenderPipelineState!
    var cubePipelineState: MTLRenderPipelineState!
    
    // Buffers
    var cubeVertexBuffer: MTLBuffer!
    var cubeIndexBuffer: MTLBuffer!
    var quadVertexBuffer: MTLBuffer!
    var quadIndexBuffer: MTLBuffer!
    
    // Texture
    var cubeTexture: MTLTexture!
    
    // Matrices and rotation
    var projectionMatrix: float4x4 = float4x4()
    var viewMatrix: float4x4 = float4x4()
    var modelMatrix: float4x4 = float4x4()
    var rotationAngle: Float = 0.0

    // Depth stencil states
    var depthStencilState: MTLDepthStencilState!
    var noDepthStencilState: MTLDepthStencilState!


    static let cubeVertices: [CubeVertex] = [
        // Front face
        CubeVertex(position: SIMD3<Float>(-0.5, -0.5,  0.5), texCoord: SIMD2<Float>(0, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5, -0.5,  0.5), texCoord: SIMD2<Float>(1, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5,  0.5,  0.5), texCoord: SIMD2<Float>(1, 0)),
        CubeVertex(position: SIMD3<Float>(-0.5,  0.5,  0.5), texCoord: SIMD2<Float>(0, 0)),
        // Back face
        CubeVertex(position: SIMD3<Float>(-0.5, -0.5, -0.5), texCoord: SIMD2<Float>(1, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5, -0.5, -0.5), texCoord: SIMD2<Float>(0, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5,  0.5, -0.5), texCoord: SIMD2<Float>(0, 0)),
        CubeVertex(position: SIMD3<Float>(-0.5,  0.5, -0.5), texCoord: SIMD2<Float>(1, 0)),
        // Left face
        CubeVertex(position: SIMD3<Float>(-0.5, -0.5, -0.5), texCoord: SIMD2<Float>(0, 1)),
        CubeVertex(position: SIMD3<Float>(-0.5, -0.5,  0.5), texCoord: SIMD2<Float>(1, 1)),
        CubeVertex(position: SIMD3<Float>(-0.5,  0.5,  0.5), texCoord: SIMD2<Float>(1, 0)),
        CubeVertex(position: SIMD3<Float>(-0.5,  0.5, -0.5), texCoord: SIMD2<Float>(0, 0)),
        // Right face
        CubeVertex(position: SIMD3<Float>( 0.5, -0.5,  0.5), texCoord: SIMD2<Float>(0, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5, -0.5, -0.5), texCoord: SIMD2<Float>(1, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5,  0.5, -0.5), texCoord: SIMD2<Float>(1, 0)),
        CubeVertex(position: SIMD3<Float>( 0.5,  0.5,  0.5), texCoord: SIMD2<Float>(0, 0)),
        // Top face
        CubeVertex(position: SIMD3<Float>(-0.5,  0.5,  0.5), texCoord: SIMD2<Float>(0, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5,  0.5,  0.5), texCoord: SIMD2<Float>(1, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5,  0.5, -0.5), texCoord: SIMD2<Float>(1, 0)),
        CubeVertex(position: SIMD3<Float>(-0.5,  0.5, -0.5), texCoord: SIMD2<Float>(0, 0)),
        // Bottom face
        CubeVertex(position: SIMD3<Float>(-0.5, -0.5, -0.5), texCoord: SIMD2<Float>(0, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5, -0.5, -0.5), texCoord: SIMD2<Float>(1, 1)),
        CubeVertex(position: SIMD3<Float>( 0.5, -0.5,  0.5), texCoord: SIMD2<Float>(1, 0)),
        CubeVertex(position: SIMD3<Float>(-0.5, -0.5,  0.5), texCoord: SIMD2<Float>(0, 0))
    ]

    static let cubeIndices: [UInt16] = [
        0, 1, 2,  0, 2, 3,    // Front
        4, 5, 6,  4, 6, 7,    // Back
        8, 9, 10, 8, 10, 11,  // Left
        12, 13, 14, 12, 14, 15, // Right
        16, 17, 18, 16, 18, 19, // Top
        20, 21, 22, 20, 22, 23  // Bottom
    ]

    static let quadVerticesData: [QuadVertex] = [
        QuadVertex(position: SIMD2<Float>(-1.0, -1.0)),
        QuadVertex(position: SIMD2<Float>( 1.0, -1.0)),
        QuadVertex(position: SIMD2<Float>(-1.0,  1.0)),
        QuadVertex(position: SIMD2<Float>( 1.0,  1.0))
    ]
    static let quadIndices: [UInt16] = [0, 1, 2, 2, 1, 3]


    init?(device: MTLDevice) {
        self.device = device
        guard let queue = device.makeCommandQueue() else { return nil }
        self.commandQueue = queue
        super.init()

        buildShadersAndPipelines()
        buildBuffers()
        loadTexture()
        buildDepthStencilStates()
        
        viewMatrix = float4x4.makeLookAt(eye: SIMD3<Float>(0, 0, 2.5), center: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
    }

    private func buildShadersAndPipelines() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load default Metal library")
        }

        let gradientVertexFunction = library.makeFunction(name: "gradient_vertex_shader")
        let gradientFragmentFunction = library.makeFunction(name: "gradient_fragment_shader")

        let gradientPipelineDescriptor = MTLRenderPipelineDescriptor()
        gradientPipelineDescriptor.label = "Gradient Pipeline"
        gradientPipelineDescriptor.vertexFunction = gradientVertexFunction
        gradientPipelineDescriptor.fragmentFunction = gradientFragmentFunction
        gradientPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        gradientPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        let gradientVertexDescriptor = MTLVertexDescriptor()
        gradientVertexDescriptor.attributes[0].format = .float2
        gradientVertexDescriptor.attributes[0].offset = 0
        gradientVertexDescriptor.attributes[0].bufferIndex = 0
        gradientVertexDescriptor.layouts[0].stride = MemoryLayout<QuadVertex>.stride
        gradientVertexDescriptor.layouts[0].stepFunction = .perVertex
        gradientPipelineDescriptor.vertexDescriptor = gradientVertexDescriptor

        do {
            gradientPipelineState = try device.makeRenderPipelineState(descriptor: gradientPipelineDescriptor)
        } catch {
            fatalError("Failed to create gradient pipeline state: \(error)")
        }

        // --- Cube Pipeline ---
        let cubeVertexFunction = library.makeFunction(name: "cube_vertex_shader")
        let cubeFragmentFunction = library.makeFunction(name: "cube_fragment_shader")

        let cubePipelineDescriptor = MTLRenderPipelineDescriptor()
        cubePipelineDescriptor.label = "Cube Pipeline"
        cubePipelineDescriptor.vertexFunction = cubeVertexFunction
        cubePipelineDescriptor.fragmentFunction = cubeFragmentFunction
        cubePipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        cubePipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        let cubeVertexDescriptor = MTLVertexDescriptor()
        cubeVertexDescriptor.attributes[0].format = .float3
        cubeVertexDescriptor.attributes[0].offset = 0
        cubeVertexDescriptor.attributes[0].bufferIndex = 0
        cubeVertexDescriptor.attributes[1].format = .float2
        cubeVertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        cubeVertexDescriptor.attributes[1].bufferIndex = 0
        cubeVertexDescriptor.layouts[0].stride = MemoryLayout<CubeVertex>.stride
        cubePipelineDescriptor.vertexDescriptor = cubeVertexDescriptor
        
        do {
            cubePipelineState = try device.makeRenderPipelineState(descriptor: cubePipelineDescriptor)
        } catch {
            fatalError("Failed to create cube pipeline state: \(error)")
        }
    }

    private func buildBuffers() {
        let cubeVertexDataSize = Renderer.cubeVertices.count * MemoryLayout<CubeVertex>.stride
        cubeVertexBuffer = device.makeBuffer(bytes: Renderer.cubeVertices, length: cubeVertexDataSize, options: [])
        
        let cubeIndexDataSize = Renderer.cubeIndices.count * MemoryLayout<UInt16>.stride
        cubeIndexBuffer = device.makeBuffer(bytes: Renderer.cubeIndices, length: cubeIndexDataSize, options: [])

        let quadVertexDataSize = Renderer.quadVerticesData.count * MemoryLayout<QuadVertex>.stride
        quadVertexBuffer = device.makeBuffer(bytes: Renderer.quadVerticesData, length: quadVertexDataSize, options: [])
        
        let quadIndexDataSize = Renderer.quadIndices.count * MemoryLayout<UInt16>.stride
        quadIndexBuffer = device.makeBuffer(bytes: Renderer.quadIndices, length: quadIndexDataSize, options: [])
    }

    private func loadTexture() {
        let textureLoader = MTKTextureLoader(device: device)
        do {
            cubeTexture = try textureLoader.newTexture(name: "sppico", scaleFactor: 1.0, bundle: nil, options: nil)
        } catch {
            fatalError("no sppico texture: \(error)")
        }
    }
    
    private func buildDepthStencilStates() {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        guard let cubeDepthState = device.makeDepthStencilState(descriptor: depthDescriptor) else {
            fatalError("cannot crreat 'cube' depth state")
        }
        self.depthStencilState = cubeDepthState

        let noDepthDescriptor = MTLDepthStencilDescriptor()
        noDepthDescriptor.depthCompareFunction = .always
        noDepthDescriptor.isDepthWriteEnabled = false
        guard let gradientDepthState = device.makeDepthStencilState(descriptor: noDepthDescriptor) else {
            fatalError("failed to create 'gradient' depth state")
        }
        self.noDepthStencilState = gradientDepthState
    }

    // MARK: - MTKViewDelegate Methods
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = float4x4.makePerspective(fovyRadians: .pi / 3, aspect: aspect, nearZ: 0.1, farZ: 100.0)
    }

    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "Main Command Buffer"

        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        // --- 1. Draw Gradient Background ---
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.loadAction = .dontCare
        renderPassDescriptor.depthAttachment.storeAction = .dontCare


        guard let gradientEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        gradientEncoder.label = "Gradient Encoder"
        gradientEncoder.setRenderPipelineState(gradientPipelineState)
        gradientEncoder.setDepthStencilState(noDepthStencilState)
        gradientEncoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: 0)
        
        var viewportSize = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))
        gradientEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)

        gradientEncoder.drawIndexedPrimitives(type: .triangle,
                                              indexCount: Renderer.quadIndices.count,
                                              indexType: .uint16,
                                              indexBuffer: quadIndexBuffer,
                                              indexBufferOffset: 0)
        gradientEncoder.endEncoding()


        // --- 2. Draw Textured Cube ---
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        renderPassDescriptor.depthAttachment.storeAction = .store

        guard let cubeEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        cubeEncoder.label = "Cube encoder"
        
        cubeEncoder.setDepthStencilState(depthStencilState)
        // Disable culling to see all faces
        cubeEncoder.setCullMode(.none) // MODIFIED: Was .back
        
        cubeEncoder.setRenderPipelineState(cubePipelineState)
        cubeEncoder.setVertexBuffer(cubeVertexBuffer, offset: 0, index: 0)

        rotationAngle += 0.005
        modelMatrix = float4x4.makeRotationY(angle: rotationAngle) * float4x4.makeRotationX(angle: rotationAngle * 0.5)

        var mvp = projectionMatrix * viewMatrix * modelMatrix
        cubeEncoder.setVertexBytes(&mvp, length: MemoryLayout<float4x4>.stride, index: 1)
        
        cubeEncoder.setFragmentTexture(cubeTexture, index: 0)

        cubeEncoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: Renderer.cubeIndices.count,
                                          indexType: .uint16,
                                          indexBuffer: cubeIndexBuffer,
                                          indexBufferOffset: 0)
        cubeEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
}


// MARK: - Matrix Math Helpers (float4x4 extensions)
extension float4x4 {
    static func makePerspective(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> float4x4 {
        let y = 1 / tan(fovyRadians * 0.5)
        let x = y / aspect
        let z = farZ / (nearZ - farZ)
        return float4x4(
            SIMD4<Float>(x, 0, 0, 0),
            SIMD4<Float>(0, y, 0, 0),
            SIMD4<Float>(0, 0, z, -1),
            SIMD4<Float>(0, 0, z * nearZ, 0)
        )
    }

    static func makeLookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
        let z = normalize(eye - center)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        let t = SIMD3<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye))
        
        return float4x4(
            SIMD4<Float>(x.x, y.x, z.x, 0),
            SIMD4<Float>(x.y, y.y, z.y, 0),
            SIMD4<Float>(x.z, y.z, z.z, 0),
            SIMD4<Float>(t.x, t.y, t.z, 1)
        )
    }
    
    static func makeRotationY(angle: Float) -> float4x4 {
        let c = cos(angle)
        let s = sin(angle)
        return float4x4(
            SIMD4<Float>(c, 0, -s, 0),
            SIMD4<Float>(0, 1,  0, 0),
            SIMD4<Float>(s, 0,  c, 0),
            SIMD4<Float>(0, 0,  0, 1)
        )
    }

    static func makeRotationX(angle: Float) -> float4x4 {
        let c = cos(angle)
        let s = sin(angle)
        return float4x4(
            SIMD4<Float>(1, 0,  0, 0),
            SIMD4<Float>(0, c,  s, 0),
            SIMD4<Float>(0, -s, c, 0),
            SIMD4<Float>(0, 0,  0, 1)
        )
    }
}


import SwiftUI

struct NetworkInfoView: View {
    @State private var selectedInterface: String = "Wi-Fi (en0)"
    let interfaces = ["Wi-Fi (en0)", "Ethernet (en1)"]
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 10) {
                Text("Select a network interface for information.")
                    .foregroundColor(.secondary)
                Picker("", selection: $selectedInterface) {
                    ForEach(interfaces, id: \.self) { iface in
                        Text(iface)
                            .foregroundColor(.primary)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 300, alignment: .leading)
                HStack(alignment: .top, spacing: 40) {
                    // Interface Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interface Information").font(.headline).foregroundColor(.white)
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Hardware Address: 60:3e:5f:7e:60:f3")
                                Text("IP Address: 192.168.1.187")
                                Text("Link Speed: N/A")
                                Text("Trans. Speed: 520 Mbit/s")
                                Text("Link Status: Active")
                                Text("Vendor: Apple Inc. (Broadcom Inc. and subsidiaries)")
                                Text("Model: N/A")
                            }
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color(.gray).opacity(0.2))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    // Transfer Statistics
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transfer Statistics").font(.headline).foregroundColor(.white)
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sent Packages: 1,829,030")
                                Text("Sent Data: 377.9 MB")
                                Text("Send Errors: 0")
                                Text("Recv Packages: 1,868,859")
                                Text("Recv Data: 406.1 MB")
                                Text("Recv Errors: 0")
                                Text("Collisions: 0")
                            }
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color(.gray).opacity(0.2))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.top, 10)
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

#if DEBUG
struct NetworkInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkInfoView()
    }
}
#endif 
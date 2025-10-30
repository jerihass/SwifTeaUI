import SwifTeaCore

@main
struct CounterMain {
    static func main() {
        SwifTea.brew(CounterApp(), fps: 30)
    }
}

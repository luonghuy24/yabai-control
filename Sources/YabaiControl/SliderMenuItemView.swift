import AppKit

final class SliderMenuItemView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private let slider = NSSlider()
    private let format: (Int) -> String
    private let onChange: (Int) -> Void
    private var lastSent: Int?

    init(title: String,
         minValue: Double,
         maxValue: Double,
         value: Double,
         width: CGFloat = 280,
         format: @escaping (Int) -> String = { "\($0)" },
         onChange: @escaping (Int) -> Void) {
        self.format = format
        self.onChange = onChange
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 50))

        let inset: CGFloat = 14
        let valueWidth: CGFloat = 70

        titleLabel.font = .menuFont(ofSize: 0)
        titleLabel.textColor = .labelColor
        titleLabel.stringValue = title
        titleLabel.frame = NSRect(x: inset, y: 27, width: width - inset * 2 - valueWidth, height: 17)

        valueLabel.font = .menuFont(ofSize: 0)
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .right
        valueLabel.stringValue = format(Int(value.rounded()))
        valueLabel.frame = NSRect(x: width - inset - valueWidth, y: 27, width: valueWidth, height: 17)

        slider.minValue = minValue
        slider.maxValue = maxValue
        slider.doubleValue = value
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderChanged)
        slider.frame = NSRect(x: inset, y: 6, width: width - inset * 2, height: 19)

        lastSent = Int(value.rounded())

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(slider)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    @objc private func sliderChanged() {
        let value = Int(slider.doubleValue.rounded())
        valueLabel.stringValue = format(value)
        guard value != lastSent else { return }
        lastSent = value
        onChange(value)
    }
}

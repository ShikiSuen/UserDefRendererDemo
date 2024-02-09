// (c) 2024 and onwards The vChewing Project (MIT-NTL License).
// ====================
// This code is released under the MIT license (SPDX-License-Identifier: MIT).

import AppKit

// MARK: - Array.deduplicate

// Extend the RangeReplaceableCollection to allow it clean duplicated characters.
// Ref: https://stackoverflow.com/questions/25738817/
public extension RangeReplaceableCollection where Element: Hashable {
  /// 使用 NSOrderedSet 處理 class 陣列的「去重複化」。
  var classDeduplicated: Self {
    NSOrderedSet(array: Array(self)).compactMap { $0 as? Element.Type } as? Self ?? self
    // 下述方法有 Bug 會在處理 KeyValuePaired 的時候崩掉，暫時停用。
    // var set = Set<Element>()
    // return filter { set.insert($0).inserted }
  }

  /// 去重複化。
  /// - Remark: 該方法不適合用來處理 class，除非該 class 遵循 Identifiable 協定。
  var deduplicated: Self {
    var set = Set<Element>()
    return filter { set.insert($0).inserted }
  }
}

// MARK: - Array Builder.

@resultBuilder
public enum ArrayBuilder<OutputModel> {
  public static func buildEither(first component: [OutputModel]) -> [OutputModel] {
    component
  }

  public static func buildEither(second component: [OutputModel]) -> [OutputModel] {
    component
  }

  public static func buildOptional(_ component: [OutputModel]?) -> [OutputModel] {
    component ?? []
  }

  public static func buildExpression(_ expression: OutputModel) -> [OutputModel] {
    [expression]
  }

  public static func buildExpression(_: ()) -> [OutputModel] {
    []
  }

  public static func buildBlock(_ components: [OutputModel]...) -> [OutputModel] {
    components.flatMap { $0 }
  }

  public static func buildArray(_ components: [[OutputModel]]) -> [OutputModel] {
    Array(components.joined())
  }
}

// MARK: - NSAlert

public extension NSAlert {
  func beginSheetModal(at window: NSWindow?, completionHandler handler: @escaping (NSApplication.ModalResponse) -> Void) {
    if let window = window ?? NSApp.keyWindow {
      beginSheetModal(for: window, completionHandler: handler)
    } else {
      handler(runModal())
    }
  }
}

// MARK: - NSOpenPanel

public extension NSOpenPanel {
  func beginSheetModal(at window: NSWindow?, completionHandler handler: @escaping (NSApplication.ModalResponse) -> Void) {
    if let window = window ?? NSApp.keyWindow {
      beginSheetModal(for: window, completionHandler: handler)
    } else {
      handler(runModal())
    }
  }
}

// MARK: - NSButton

public extension NSButton {
  convenience init(verbatim title: String, target: AnyObject?, action: Selector?) {
    self.init()
    self.title = title
    self.target = target
    self.action = action
    bezelStyle = .rounded
  }

  convenience init(_ title: String, target: AnyObject?, action: Selector?) {
    self.init(verbatim: title.localized, target: target, action: action)
  }
}

// MARK: - Convenient Constructor for NSEdgeInsets.

public extension NSEdgeInsets {
  static func new(all: CGFloat? = nil, top: CGFloat? = nil, bottom: CGFloat? = nil, left: CGFloat? = nil, right: CGFloat? = nil) -> NSEdgeInsets {
    NSEdgeInsets(top: top ?? all ?? 0, left: left ?? all ?? 0, bottom: bottom ?? all ?? 0, right: right ?? all ?? 0)
  }
}

// MARK: - Constrains and Box Container Modifier.

public extension NSView {
  @discardableResult func makeSimpleConstraint(
    _ attribute: NSLayoutConstraint.Attribute,
    relation: NSLayoutConstraint.Relation,
    value: CGFloat?
  ) -> NSView {
    guard let value = value else { return self }
    translatesAutoresizingMaskIntoConstraints = false
    let widthConstraint = NSLayoutConstraint(
      item: self, attribute: attribute, relatedBy: relation, toItem: nil,
      attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: value
    )
    addConstraint(widthConstraint)
    return self
  }

  func boxed(title: String = "") -> NSBox {
    let maxDimension = fittingSize
    let result = NSBox()
    result.title = title.localized
    if result.title.isEmpty {
      result.titlePosition = .noTitle
    }
    let minWidth = max(maxDimension.width + 12, result.intrinsicContentSize.width)
    let minHeight = max(maxDimension.height + result.titleRect.height + 14, result.intrinsicContentSize.height)
    result.makeSimpleConstraint(.width, relation: .greaterThanOrEqual, value: minWidth)
    result.makeSimpleConstraint(.height, relation: .greaterThanOrEqual, value: minHeight)
    result.contentView = self
    return result
  }
}

// MARK: - Stacks

public extension NSStackView {
  var requiresConstraintBasedLayout: Bool {
    true
  }

  static func buildSection(
    _ orientation: NSUserInterfaceLayoutOrientation = .vertical,
    width: CGFloat? = nil,
    withDividers: Bool = true,
    @ArrayBuilder<NSView?> views: () -> [NSView?]
  ) -> NSStackView? {
    let viewsRendered = views().compactMap {
      // 下述註解是用來協助偵錯的。
      // $0?.wantsLayer = true
      // $0?.layer?.backgroundColor = NSColor.red.cgColor
      $0
    }
    guard !viewsRendered.isEmpty else { return nil }
    var itemWidth = width
    var splitterDelta: CGFloat = 4
    if #unavailable(macOS 10.10) {
      splitterDelta = 8
    }
    splitterDelta = withDividers ? splitterDelta : 0
    if let width = width, orientation == .horizontal, viewsRendered.count > 0 {
      itemWidth = (width - splitterDelta) / CGFloat(viewsRendered.count) - 6
    }
    func giveViews() -> [NSView?] { viewsRendered }
    let result = build(orientation, divider: withDividers, width: itemWidth, views: giveViews)?
      .withInsets(.new(all: 4))
    return result
  }

  static func build(
    _ orientation: NSUserInterfaceLayoutOrientation,
    divider: Bool = false,
    width: CGFloat? = nil,
    height: CGFloat? = nil,
    insets: NSEdgeInsets? = nil,
    @ArrayBuilder<NSView?> views: () -> [NSView?]
  ) -> NSStackView? {
    let result = views().compactMap {
      $0?
        .makeSimpleConstraint(.width, relation: .equal, value: width)
        .makeSimpleConstraint(.height, relation: .equal, value: height)
    }
    guard !result.isEmpty else { return nil }
    return result.stack(orientation, divider: divider)?.withInsets(insets)
  }

  func withInsets(_ newValue: NSEdgeInsets?) -> NSStackView {
    edgeInsets = newValue ?? edgeInsets
    return self
  }
}

public extension Array where Element == NSView {
  func stack(
    _ orientation: NSUserInterfaceLayoutOrientation,
    divider: Bool = false,
    insets: NSEdgeInsets? = nil
  ) -> NSStackView? {
    guard !isEmpty else { return nil }
    let outerStack = NSStackView()
    if #unavailable(macOS 10.11) {
      outerStack.hasEqualSpacing = true
    } else {
      outerStack.distribution = .equalSpacing
    }
    outerStack.orientation = orientation

    if #unavailable(macOS 10.10) {
      outerStack.spacing = Swift.max(1, outerStack.spacing) - 1
    }

    outerStack.setHuggingPriority(.fittingSizeCompression, for: .horizontal)
    outerStack.setHuggingPriority(.fittingSizeCompression, for: .vertical)

    forEach { subView in
      if divider, !outerStack.views.isEmpty {
        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.2).cgColor
        switch orientation {
        case .horizontal:
          divider.makeSimpleConstraint(.width, relation: .equal, value: 1)
        case .vertical:
          divider.makeSimpleConstraint(.height, relation: .equal, value: 1)
        @unknown default: break
        }
        divider.translatesAutoresizingMaskIntoConstraints = false
        outerStack.addView(divider, in: orientation == .horizontal ? .leading : .top)
      }
      subView.layoutSubtreeIfNeeded()
      switch orientation {
      case .horizontal:
        subView.makeSimpleConstraint(.height, relation: .greaterThanOrEqual, value: subView.intrinsicContentSize.height)
        subView.makeSimpleConstraint(.width, relation: .greaterThanOrEqual, value: subView.intrinsicContentSize.width)
      case .vertical:
        subView.makeSimpleConstraint(.width, relation: .greaterThanOrEqual, value: subView.intrinsicContentSize.width)
        subView.makeSimpleConstraint(.height, relation: .greaterThanOrEqual, value: subView.intrinsicContentSize.height)
      @unknown default: break
      }
      subView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
      subView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
      subView.translatesAutoresizingMaskIntoConstraints = false
      outerStack.addView(subView, in: orientation == .horizontal ? .leading : .top)
    }

    switch orientation {
    case .horizontal:
      outerStack.alignment = .centerY
    case .vertical:
      outerStack.alignment = .leading
    @unknown default: break
    }
    return outerStack.withInsets(insets)
  }
}

// MARK: - Make NSAttributedString into Label

public extension NSAttributedString {
  func makeNSLabel(fixWidth: CGFloat? = nil) -> NSTextField {
    let textField = NSTextField()
    textField.attributedStringValue = self
    textField.isEditable = false
    textField.isBordered = false
    textField.backgroundColor = .clear
    if let fixWidth = fixWidth {
      textField.preferredMaxLayoutWidth = fixWidth
    }
    return textField
  }
}

// MARK: - Make String into Label

public extension String {
  func makeNSLabel(descriptive: Bool = false, localized: Bool = true, fixWidth: CGFloat? = nil) -> NSTextField {
    let rawAttributedString = NSMutableAttributedString(string: localized ? self.localized : self)
    rawAttributedString.addAttributes([.kern: 0], range: .init(location: 0, length: rawAttributedString.length))
    let textField = rawAttributedString.makeNSLabel(fixWidth: fixWidth)
    if descriptive {
      if #available(macOS 10.10, *) {
        textField.textColor = .secondaryLabelColor
      } else {
        textField.textColor = .textColor.withAlphaComponent(0.55)
      }
      textField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    }
    return textField
  }
}

// MARK: - NSTabView

public extension NSTabView {
  struct TabPage {
    public let title: String
    public let view: NSView

    public init?(title: String, view: NSView?) {
      self.title = title
      guard let view = view else { return nil }
      self.view = view
    }

    public init(title: String, view: NSView) {
      self.title = title
      self.view = view
    }

    public init?(title: String, @ArrayBuilder<NSView?> views: () -> [NSView?]) {
      self.title = title
      let viewsRendered = views()
      guard !viewsRendered.isEmpty else { return nil }
      func giveViews() -> [NSView?] { viewsRendered }
      let result = NSStackView.build(.vertical, insets: .new(all: 14, top: 0), views: giveViews)
      guard let result = result else { return nil }
      view = result
    }
  }

  static func build(
    @ArrayBuilder<TabPage?> pages: () -> [TabPage?]
  ) -> NSTabView? {
    let tabPages = pages().compactMap { $0 }
    guard !tabPages.isEmpty else { return nil }
    let finalTabView = NSTabView()
    tabPages.forEach { currentPage in
      finalTabView.addTabViewItem({
        let currentItem = NSTabViewItem(identifier: UUID())
        currentItem.label = currentPage.title.localized
        let stacked = NSStackView.build(.vertical) {
          currentPage.view
        }
        stacked?.alignment = .centerX
        currentItem.view = stacked
        return currentItem
      }())
    }
    return finalTabView
  }
}

// MARK: - NSMenu

public extension NSMenu {
  @discardableResult func appendItems(_ target: AnyObject? = nil, @ArrayBuilder<NSMenuItem?> items: () -> [NSMenuItem?]) -> NSMenu {
    let theItems = items()
    for currentItem in theItems {
      guard let currentItem = currentItem else { continue }
      addItem(currentItem)
      guard let target = target else { continue }
      currentItem.target = target
      currentItem.submenu?.propagateTarget(target)
    }
    return self
  }

  @discardableResult func propagateTarget(_ obj: AnyObject?) -> NSMenu {
    for currentItem in items {
      currentItem.target = obj
      currentItem.submenu?.propagateTarget(obj)
    }
    return self
  }

  static func buildSubMenu(verbatim: String?, @ArrayBuilder<NSMenuItem?> items: () -> [NSMenuItem?]) -> NSMenuItem? {
    guard let verbatim = verbatim, !verbatim.isEmpty else { return nil }
    let newItem = NSMenu.Item(verbatim: verbatim)
    newItem?.submenu = .init(title: verbatim).appendItems(items: items)
    return newItem
  }

  static func buildSubMenu(_ title: String?, @ArrayBuilder<NSMenuItem?> items: () -> [NSMenuItem?]) -> NSMenuItem? {
    guard let title = title?.localized, !title.isEmpty else { return nil }
    return buildSubMenu(verbatim: title, items: items)
  }

  typealias Item = NSMenuItem
}

public extension Array where Element == NSMenuItem? {
  func propagateTarget(_ obj: AnyObject?) {
    forEach { currentItem in
      guard let currentItem = currentItem else { return }
      currentItem.target = obj
      currentItem.submenu?.propagateTarget(obj)
    }
  }
}

public extension NSMenuItem {
  convenience init?(verbatim: String?) {
    guard let verbatim = verbatim, !verbatim.isEmpty else { return nil }
    self.init(title: verbatim, action: nil, keyEquivalent: "")
  }

  convenience init?(_ title: String?) {
    guard let title = title?.localized, !title.isEmpty else { return nil }
    self.init(verbatim: title)
  }

  @discardableResult func hotkey(_ keyEquivalent: String, mask: NSEvent.ModifierFlags? = nil) -> NSMenuItem {
    keyEquivalentModifierMask = mask ?? keyEquivalentModifierMask
    self.keyEquivalent = keyEquivalent
    return self
  }

  @discardableResult func state(_ givenState: Bool) -> NSMenuItem {
    state = givenState ? .on : .off
    return self
  }

  @discardableResult func act(_ action: Selector) -> NSMenuItem {
    self.action = action
    return self
  }

  @discardableResult func nulled(_ condition: Bool) -> NSMenuItem? {
    condition ? nil : self
  }

  @discardableResult func mask(_ flags: NSEvent.ModifierFlags) -> NSMenuItem {
    keyEquivalentModifierMask = flags
    return self
  }

  @discardableResult func represent(_ object: Any?) -> NSMenuItem {
    representedObject = object
    return self
  }

  @discardableResult func tag(_ givenTag: Int?) -> NSMenuItem {
    guard let givenTag = givenTag else { return self }
    tag = givenTag
    return self
  }
}

// MARK: - Strings.localized

public extension String {
  var localized: String {
    NSLocalizedString(self, comment: "")
  }
}

/// --------------------
/// 以上都是 AppKit 與 Swift 的擴充。接下來才是正篇。
/// --------------------

// MARK: - 讓 UserDefaults 具備應對單元測試的能力

public extension UserDefaults {
  // 內部標記，看當前應用是否處於單元測試模式。
  static var pendingUnitTests = false

  static var unitTests = UserDefaults(suiteName: "UnitTests")

  static var current: UserDefaults {
    pendingUnitTests ? .unitTests ?? .standard : .standard
  }
}

// MARK: - UserDefaults Keys。

protocol UserDefProtocol {
  /// 可以實作介面的 Case。
  static var renderableCases: [UserDef] { get }
  /// 資料種類。
  var dataType: UserDef.DataType { get }
  /// 中繼資料。不是所有 UserDefault Keys 都會被做到 UI 介面當中，所以就用了 nullable。
  var metaData: UserDef.MetaData? { get }
}

public enum UserDef: String {
  case testStringSansOptions = "kStringsSansOptions"
  case testStringWithComboBox = "kStringsWithComboBox"
  case testStringWithFixedOptions = "kStringsWithFixedOptions"
  case testBool = "kBool"
  case testIntWithOptions = "kIntWithOptions"
  case testIntSansOptions = "kIntSansOptions"
}

// MARK: - UserDef 功能特性擴充實作

extension UserDef: CaseIterable, Identifiable {
  public enum DataType: CaseIterable {
    case string, bool, integer, double, array, dictionary, other
  }

  public var id: String { rawValue }

  public struct MetaData {
    public var userDef: UserDef
    public var shortTitle: String?
    public var control: AnyObject?
    public var prompt: String?
    public var inlinePrompt: String?
    public var popupPrompt: String?
    public var description: String?
    public var minimumOS: Double = 10.9
    public var options: [(Int, String)]?
    public var optionsRepresentable: [(Any, String)]?
    public var toolTip: String?
  }

  // MARK: - 快照方法

  /// 清空當前的 UserDefaults。
  public static func resetAll() {
    UserDef.allCases.forEach {
      UserDefaults.current.removeObject(forKey: $0.rawValue)
    }
  }

  /// 讀入 UserDefaults 快照備份。
  public static func load(from snapshot: Snapshot) {
    let data = snapshot.data
    guard !data.isEmpty else { return }
    UserDef.allCases.forEach {
      UserDefaults.current.set(data[$0.rawValue], forKey: $0.rawValue)
    }
  }

  /// 用來給 UserDefaults Container 做快照備份的結構。
  public struct Snapshot {
    public var data: [String: Any] = [:]
    public init() {
      UserDef.allCases.forEach {
        data[$0.rawValue] = UserDefaults.current.object(forKey: $0.rawValue)
      }
    }
  }
}

// MARK: - UserDefaults 資料類型與中繼資料

extension UserDef: UserDefProtocol {
  static var renderableCases: [UserDef] {
    Self.allCases.filter { $0.metaData != nil }
  }

  var dataType: DataType {
    switch self {
    case .testStringSansOptions: .string
    case .testStringWithComboBox: .string
    case .testStringWithFixedOptions: .string
    case .testBool: .bool
    case .testIntWithOptions: .integer
    case .testIntSansOptions: .integer
    }
  }

  var metaData: MetaData? {
    switch self {
    case .testStringSansOptions: return .init(
        userDef: self, shortTitle: "測試以 String 為資料值的填寫選項",
        description: "該選項沒有備選內容，請手動填寫。"
      )
    case .testStringWithComboBox: return .init(
        userDef: self, shortTitle: "測試以 String 為資料值的填寫選項",
        description: "該選項有備選內容。選擇的內容與寫入 UserDefaults 的是同樣的 String。",
        options: [ // 此處數字無意義。
          (0, "參考填寫一"),
          (1, "參考填寫二"),
          (3, "參考填寫三"),
        ]
      )
    case .testStringWithFixedOptions: return .init(
        userDef: self, shortTitle: "測試以 String 為資料值的備選選項",
        description: "該選項有備選內容。選擇的內容是國語，寫入 UserDefaults 的是日語。",
        optionsRepresentable: [
          ("もう待ちきれないよ！早く出してくれ！", "已經等不及了！趕緊端上來吧！"),
          ("非常に新鮮で、非常に美味しい", "非常的新鮮、非常的美味。"),
        ]
      )
    case .testBool: return .init(
        userDef: self, shortTitle: "測試備選選項",
        description: "該選項有備選內容。選擇的內容是國語，寫入 UserDefaults 的是 Bool。",
        options: [
          (0, "停用"),
          (1, "啟用"),
        ]
      )
    case .testIntWithOptions: return .init(
        userDef: self,
        shortTitle: "測試數字被選項",
        description: "該選項有備選內容。選擇的內容是日語，寫入 UserDefaults 的是數字。",
        minimumOS: 10.11,
        options: [
          (114, "いいよ"),
          (514, "こいよ"),
          (1919, "いくいく"),
          (810, "はいれ"),
        ]
      )
    case .testIntSansOptions: return nil // 這次先不實作這個，留著當各位的練習作業。
    }
  }
}

// MARK: - UserDefRenderableCocoa 類型

public class UserDefRenderableCocoa: NSObject, Identifiable {
  public let def: UserDef
  public var id: String { def.rawValue }
  public var optionsLocalized: [(Int, String)?] = []
  public var optionsLocalizedRepresentable: [(Any, String)?] = [] // 非 Int 型資料專用。
  public var inlineDescriptionLocalized: String?
  public var hideTitle: Bool = false
  public var mainViewOverride: (() -> NSView?)?
  public var currentControl: NSControl?
  public var tinySize: Bool = false

  public init(def: UserDef) {
    self.def = def
    if let rawOptions = def.metaData?.options, !rawOptions.isEmpty {
      optionsLocalized = rawOptions.map { ($0.0, $0.1.localized) }
    }
    if let rawOptions = def.metaData?.optionsRepresentable, !rawOptions.isEmpty {
      optionsLocalizedRepresentable = rawOptions.map { ($0.0, $0.1.localized) }
    }

    super.init()
    guard let metaData = def.metaData else {
      inlineDescriptionLocalized = nil
      return
    }
    var stringStack = [String]()
    if let promptText = metaData.inlinePrompt?.localized, !promptText.isEmpty {
      stringStack.append(promptText)
    }
    if let descText = metaData.description?.localized, !descText.isEmpty {
      stringStack.append(descText)
    }
    if metaData.minimumOS > 10.9 {
      var strOSReq = " "
      strOSReq += String(
        format: "This feature requires macOS %@ and above.".localized, arguments: ["12.0"]
      )
      stringStack.append(strOSReq)
    }
    currentControl = renderFunctionControl()
    guard !stringStack.isEmpty else {
      inlineDescriptionLocalized = nil
      return
    }
    inlineDescriptionLocalized = stringStack.joined(separator: "\n")
  }
}

public extension UserDefRenderableCocoa {
  func render(fixWidth fixedWith: CGFloat? = nil) -> NSView? {
    let result: NSStackView? = NSStackView.build(.vertical) {
      renderMainLine(fixedWidth: fixedWith)
      renderDescription(fixedWidth: fixedWith)
    }
    result?.makeSimpleConstraint(.width, relation: .equal, value: fixedWith)
    return result
  }

  func renderDescription(fixedWidth: CGFloat? = nil) -> NSTextField? {
    guard let text = inlineDescriptionLocalized else { return nil }
    let textField = text.makeNSLabel(descriptive: true)
    if #available(macOS 10.10, *), tinySize {
      textField.controlSize = .small
      textField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    }
    textField.preferredMaxLayoutWidth = fixedWidth ?? 0
    return textField
  }

  func renderMainLine(fixedWidth: CGFloat? = nil) -> NSView? {
    if let mainViewOverride = mainViewOverride {
      return mainViewOverride()
    }
    guard let control: NSView = currentControl ?? renderFunctionControl() else { return nil }
    let controlWidth = control.fittingSize.width
    let textLabel: NSTextField? = {
      if !hideTitle, let strTitle = def.metaData?.shortTitle {
        return strTitle.makeNSLabel()
      }
      return nil
    }()
    let result = NSStackView.build(.horizontal) {
      if !hideTitle, let textlabel = textLabel {
        textlabel
        NSView()
      }
      control
    }
    if let fixedWidth = fixedWidth {
      textLabel?.preferredMaxLayoutWidth = fixedWidth - controlWidth
    }
    textLabel?.sizeToFit()
    return result
  }

  private func renderFunctionControl() -> NSControl? {
    var result: NSControl? {
      switch def.dataType {
      case .string where optionsLocalizedRepresentable.isEmpty && optionsLocalized.isEmpty:
        let field = NSTextField()
        field.makeSimpleConstraint(.width, relation: .equal, value: 128)
        field.font = NSFont.systemFont(ofSize: 12)
        field.bind(
          .value,
          to: NSUserDefaultsController.shared,
          withKeyPath: "values.\(def.rawValue)"
        )
        return field
      case .string where optionsLocalizedRepresentable.isEmpty && !optionsLocalized.isEmpty:
        let comboBox = NSComboBox()
        comboBox.makeSimpleConstraint(.width, relation: .equal, value: 128)
        comboBox.font = NSFont.systemFont(ofSize: 12)
        comboBox.intercellSpacing = NSSize(width: 0.0, height: 10.0)
        comboBox.addItems(withObjectValues: optionsLocalized.map(\.?.1) as [Any])
        comboBox.bind(
          .value,
          to: NSUserDefaultsController.shared,
          withKeyPath: "values.\(def.rawValue)"
        )
        return comboBox
      case .bool where optionsLocalized.isEmpty:
        let checkBox: NSControl
        if #unavailable(macOS 10.15) {
          checkBox = NSButton()
          (checkBox as? NSButton)?.setButtonType(.switch)
          (checkBox as? NSButton)?.title = ""
        } else {
          checkBox = NSSwitch()
          checkBox.controlSize = .mini
        }
        checkBox.bind(
          .value,
          to: NSUserDefaultsController.shared,
          withKeyPath: "values.\(def.rawValue)",
          options: [.continuouslyUpdatesValue: true]
        )
        // 特殊情形結束

        return checkBox
      case .integer, .double,
           .bool where !optionsLocalized.isEmpty,
           .string where !optionsLocalizedRepresentable.isEmpty:
        let dropMenu: NSMenu = .init()
        let btnPopup = NSPopUpButton()
        var itemShouldBeChosen: NSMenuItem?
        if !optionsLocalizedRepresentable.isEmpty {
          btnPopup.bind(
            .selectedObject,
            to: NSUserDefaultsController.shared,
            withKeyPath: "values.\(def.rawValue)",
            options: [.continuouslyUpdatesValue: true]
          )
          optionsLocalizedRepresentable.forEach { entity in
            guard let obj = entity?.0, let title = entity?.1.localized else {
              dropMenu.addItem(.separator())
              return
            }
            let newItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            newItem.representedObject = .init(obj)
            // 這裡可能需要額外檢查一下。
            if let obj = obj as? AnyHashable, let rhs = UserDefaults.current.object(forKey: def.rawValue) as? AnyHashable, obj == rhs {
              itemShouldBeChosen = newItem
            }
            dropMenu.addItem(newItem)
          }
        } else {
          btnPopup.bind(
            .selectedTag,
            to: NSUserDefaultsController.shared,
            withKeyPath: "values.\(def.rawValue)",
            options: [.continuouslyUpdatesValue: true]
          )
          optionsLocalized.forEach { entity in
            guard let tag = entity?.0, let title = entity?.1.localized else {
              dropMenu.addItem(.separator())
              return
            }
            let newItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            newItem.tag = tag
            if tag == UserDefaults.current.integer(forKey: def.rawValue) {
              itemShouldBeChosen = newItem
            }
            if Double(tag) == UserDefaults.current.double(forKey: def.rawValue) {
              itemShouldBeChosen = newItem
            }
            dropMenu.addItem(newItem)
          }
        }
        btnPopup.menu = dropMenu
        btnPopup.font = NSFont.systemFont(ofSize: 12)
        btnPopup.setFrameSize(btnPopup.fittingSize)
        btnPopup.select(itemShouldBeChosen)
        return btnPopup
      case .array, .dictionary, .other: return nil // 根據自己的需求實作即可。
      default: return nil
      }
    }
    if #available(macOS 10.10, *), tinySize {
      result?.controlSize = .small
      return result?.makeSimpleConstraint(.height, relation: .greaterThanOrEqual, value: Swift.max(14, result?.fittingSize.height ?? 14)) as? NSControl
    }
    return result?.makeSimpleConstraint(.height, relation: .greaterThanOrEqual, value: Swift.max(16, result?.fittingSize.height ?? 16)) as? NSControl
  }
}

// MARK: - External Extensions.

public extension UserDef {
  func render(fixWidth: CGFloat? = nil, extraOps: ((inout UserDefRenderableCocoa) -> Void)? = nil) -> NSView? {
    var renderable = toCocoaRenderable()
    extraOps?(&renderable)
    return renderable.render(fixWidth: fixWidth)
  }

  func toCocoaRenderable() -> UserDefRenderableCocoa {
    .init(def: self)
  }
}

// MARK: - 寫一個範例 View

public class SampleSettingsView: NSViewController {
  let windowWidth: CGFloat = 577
  let contentWidth: CGFloat = 512

  override public func loadView() {
    view = body ?? .init()
    (view as? NSStackView)?.alignment = .centerX
    view.makeSimpleConstraint(.width, relation: .equal, value: windowWidth)
  }

  var body: NSView? {
    NSStackView.build(.vertical, insets: .new(all: 14)) {
      NSStackView.build(.horizontal, insets: .new(all: 0, left: 16, right: 16)) {
        "隨便寫個抬頭文字介紹一下頁面。".makeNSLabel(fixWidth: contentWidth)
        NSView()
      }
      NSStackView.buildSection(width: contentWidth) {
        for currentCase in UserDef.renderableCases {
          currentCase.render(fixWidth: contentWidth) { _ in
            // renderable.currentControl = NSButton() // 可以這樣換掉控件。
          }
        }
      }?.boxed()
      NSStackView.build(.horizontal, insets: .new(all: 0, left: 16, right: 16)) {
        "這是腳註問姿。".makeNSLabel(descriptive: true, fixWidth: contentWidth)
        NSView()
      }
      NSView().makeSimpleConstraint(.height, relation: .equal, value: NSFont.systemFontSize)
    }
  }

  @IBAction func sanityCheck(_: NSControl) {}
}

@available(macOS 14.0, *)
#Preview(traits: .fixedLayout(width: 600, height: 768)) {
  SampleSettingsView()
}

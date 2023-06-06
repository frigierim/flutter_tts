
class Voice {
  String name;
  String locale;

  Voice(
    this.name,
    this.locale,
  );

   bool operator==(Object other) =>
    other is Voice && (other.name == name && other.locale == locale);

  int get hashCode => Object.hash(name, locale);
}

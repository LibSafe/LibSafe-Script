# LibSafe
iOS Objective-C -> Makes open source libs possible to use in closed source libs without risk of conflicts (duplicate symbols)

LibSafe is a bash script that allows you to create static/dynamic library or Framework that can be included multiple times without class conflicts.

The simple way to explain this is that the class' names will be modified to unique names whenever you run the LibSafe script on your source code.

The original @interface or @protocol name will be available as a #define at the top of the file but refer to a randomized name instead. The names of the class' header and implementation files will still be the same so importing and referencing the files will be just like normal.


## CocoaPods
Pods based on LibSafe are safe to use in your closed source framework or library thanks to the names being randomized in the compiled product. Even if another closed source framework implements the exact same pod your framework will not cause any duplicate symbols.

A typical usecase would be an open source crash recorder like [OSCR](http://github.com/PatrikNyblad/OSCR) that can be embedded into your closed source framework to let you record crashes and submit reports so you can keep your framework quality at the top. Even if the app or another framework included in the app use OSCR the class names would be randomized and thus not behave badly.


## Features
* Scopes `@interface` and `@protocol` names so that you do not have a problem duplicate symbols if you import the same code twice.
* Allows you access to a random identifier that you can use to scope folders/files when writing data to disk.

## Known limitations
Right now we only handle Objective-C code which makes sense since Swift is not really suited for closed source code anyway.

* No Swift support
* Only supports @interface and @protocol
* No support for scoping static variables


## Example usage
To use the LibSafe script on a folder of source files called `Classes` run this in a terminal:

`$ ./LibSafe.sh Classes`

The LibSafe script can also write to a special header file to give you access to the random scoping string used. You can use this random string to scope access to the file system so that one implementation of your code does not mess with other implementations of the same code base.

To enable this header, create a file called `LibSafe-Header.h` somewhere under the folder you pass in as the first argument to the LibSafe script.
Example define found in file `LibSafe-Header.h`:
```objc
/* LibSafe Auto Generated Header */
...
#define LIBSAFE_RANDOM @"gKucoFysZpQUkHFP"
...
```


#### CocoaPods
The best way to use this script together with CocoaPods is to add it to the `prepare_command` in your Podspec file. The command defined there is executed when a user installs the pod to their project.

```ruby
Pod::Spec.new do |s|
  s.name             = 'LibSafe'
  s.version          = '0.0.1'
  s.summary          = 'This is a sample pod to demonstrate how the LibSafe script should be used in a CocoaPod.'

  ...

  s.source_files = 'Classes/**/*'

  ## Here LibSafe is triggered once when you install this pod, pass the class folder as the first argument
  s.prepare_command = './LibSafe.sh Classes'
end
```

## Author
Patrik Nyblad, patrik.nyblad@gmail.com


## Changelog

#### 0.1.0
First release of LibSafe


## License
LibSafe is available under the MIT license. See the LICENSE file for more info.

package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.Lib;

using StringTools;

class Paths
{
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static var localTrackedAssets:Array<String> = [];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		var counter:Int = 0;
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key))
			{
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					var isTexture:Bool = currentTrackedTextures.exists(key);
					if (isTexture)
					{
						var texture = currentTrackedTextures.get(key);
						texture.dispose();
						texture = null;
						currentTrackedTextures.remove(key);
					}
					OpenFlAssets.cache.removeBitmapData(key);
					OpenFlAssets.cache.clearBitmapData(key);
					OpenFlAssets.cache.clear(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
					counter++;
				}
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		var counterAssets:Int = 0;

		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				OpenFlAssets.cache.removeBitmapData(key);
				OpenFlAssets.cache.clearBitmapData(key);
				OpenFlAssets.cache.clear(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
				counterAssets++;
			}
		}

		// clear all sounds that are cached
		var counterSound:Int = 0;
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && key != null)
			{
				// trace('test: ' + dumpExclusions, key);
				OpenFlAssets.cache.removeSound(key);
				OpenFlAssets.cache.clearSounds(key);
				currentTrackedSounds.remove(key);
				counterSound++;
			}
		}

		// Clear everything everything that's left
		var counterLeft:Int = 0;
		for (key in OpenFlAssets.cache.getKeys())
		{
			if (!localTrackedAssets.contains(key) && key != null)
			{
				OpenFlAssets.cache.clear(key);
				counterLeft++;
			}
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
	}

	static public var currentLevel:String;

	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);

	inline static function getLibraryPathForce(file:String, library:String)
		return '$library:assets/$library/$file';

	inline public static function getPreloadPath(file:String = '')
		return 'assets/$file';

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
		return getPath(file, type, library);

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);

	inline static public function xml(key:String, ?library:String)
		return getPath('data/$key.xml', TEXT, library);

	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', TEXT, library);

	inline static public function jsonHidden(key:String)
		return getPath('data/$key.json', TEXT, 'hiddenContent');

	inline static public function lua(key:String, ?library:String)
		return getPath('data/$key.lua', TEXT, library);

	inline static public function video(key:String)
		return 'assets/videos/$key.mp4';

	static public function sound(key:String, ?library:String, ?cache:Bool = true):Sound
		return returnSound('sounds', key, library, cache);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String, ?cache:Bool = true)
		return returnSound('sounds', key + FlxG.random.int(min, max), library, cache);

	inline static public function music(key:String, ?library:String, ?cache:Bool = true):Sound
		return returnSound('music', key, library, cache);

	inline static public function voices(song:String, ?cache:Bool = true, ?type:String = 'none'):Sound
	{
		final songFormat:String = StringTools.replace(song, " ", "-").toLowerCase();
		return switch (type)
		{
			case 'hidden':
				return returnSound('songs', songFormat + '/Voices', 'hiddenContent', cache);
			case 'easy':
				return returnSound('songs', songFormat + '/Voices-easy', null, cache);
			default:
				return returnSound('songs', songFormat + '/Voices', null, cache);
		}
	}

	inline static public function inst(song:String, ?cache:Bool = true, ?type:String = 'none'):Sound
	{
		final songFormat:String = StringTools.replace(song, " ", "-").toLowerCase();
		return switch (type)
		{
			case 'hidden':
				return returnSound('songs', songFormat + '/Inst', 'hiddenContent', cache);
			case 'easy':
				return returnSound('songs', songFormat + '/Inst-easy', null, cache);
			default:
				return returnSound('songs', songFormat + '/Inst', null, cache);
		}
	}

	inline static public function image(key:String, ?library:String, ?gpurender:Bool = false):FlxGraphic
		return returnGraphic(key, library, gpurender);

	inline static public function font(key:String)
		return 'assets/fonts/$key';

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(image(key, library, true), file('images/$key.xml', library));

	inline static public function getPackerAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, true), file('images/$key.txt', library));

	public static function returnGraphic(key:String, ?library:String, ?gpurender:Bool = false):FlxGraphic
	{
		var path:String = getPath('images/$key.png', IMAGE, library);
		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var newGraphic:FlxGraphic = null;
				var bitmap:BitmapData = OpenFlAssets.getBitmapData(path);

				if (gpurender)
				{
					switch (FlxG.save.data.render)
					{
						case 1:
							var texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true);
							texture.uploadFromBitmapData(bitmap);
							currentTrackedTextures.set(path, texture);
							bitmap.dispose();
							bitmap.disposeImage();
							bitmap = null;
							newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, path);
						case 2:
							var texture = Lib.current.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true);
							texture.uploadFromBitmapData(bitmap);
							currentTrackedTextures.set(path, texture);
							bitmap.dispose();
							bitmap.disposeImage();
							bitmap = null;
							newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, path);
						default:
							newGraphic = FlxGraphic.fromBitmapData(bitmap, false, path);
					}
				}
				else
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, path);

				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}

			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}

		trace('oh no its returning null NOOOO');
		return null;
	}

	public static function returnSound(path:String, key:String, ?library:String, ?cache:Bool = true):Sound
	{
		var gottenPath:String;

		if (path == 'songs' && library == null)
			gottenPath = getPath('$key.ogg', SOUND, 'songs');
		else
			gottenPath = getPath('$path/$key.ogg', SOUND, library);

		if (OpenFlAssets.exists(gottenPath, SOUND))
		{
			if (!currentTrackedSounds.exists(gottenPath))
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(gottenPath, cache));

			localTrackedAssets.push(gottenPath);
			return currentTrackedSounds.get(gottenPath);
		}

		trace('oh no its returning null NOOOO');
		return null;
	}
}

package com.akifox.plik.gui;

import com.akifox.plik.*;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
using hxColorToolkit.ColorToolkit;

class Box extends SpriteContainer implements IStyle {


    //*****************************************************************

    var _id:String;
    public var id(get,set):String;
    private function get_id():String {return _id;}
    private function set_id(value:String):String {
      return _id = value;
    }
    //*****************************************************************

    var _style:Style = new Style();
    public var style(get,set):Style;
    private function get_style():Style {return _style;}
    private function set_style(value:Style):Style {
      _style = value;
      this.draw();
      return value;
    }

  	public function new (style:Style) {
  		super();
      _style = style;
      _id = "generic_box";
  	}

    public override function destroy() {
      super.destroy();
    }

    public function getNetWidth():Float {
      return Math.max(this.width,style.minWidth);
    }

    public function getNetHeight():Float {
      return Math.max(this.height,style.minHeight);
    }

    public function getGrossWidth():Float {
      return getNetWidth()+_style.padding*2;//+_style.outline_size/2;
    }

    public function getGrossHeight():Float {
      return getNetHeight()+_style.padding*2;//+_style.outline_size/2;
    }

    public function draw(?width:Float=0,?height:Float=0,?isSelected:Bool=false) {
		  graphics.clear();
      if (width<0) width = getGrossWidth();
      if (height<0) height = getGrossWidth();
      Style.drawBackground(this,_style,isSelected,false,width,height);
    }

}

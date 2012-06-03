/*
* Copyright (c) 2008 Michael A. Jordan
* Copyright (c) 2009 Adobe Systems, Inc.
* All rights reserved.
* 
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
* 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* 3. Neither the name of the copyright holders nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
* 
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.swffocus 
{
	import fl.managers.FocusManager;
	
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FocusEvent;
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	import flash.utils.setTimeout; 
	
	
	/**
	 *  SWFFocus intends to solve a keyboard accessibility related problem that 
	 *  occurs on browsers other than Internet Explorer. 
	 
	 *  <p>The problem is that it is impossible for keyboard users to move focus 
	 *  into an embedded Flash movie, and once focus is inside the Flash content 
	 *  it is impossible to move it back to the HTML content without a mouse.</p>
	 *  <p>This class injects JavaScript into the document embedding the Flash 
	 *  movie. This script  makes it possible to tab into the Flash movie. 
	 *  Additionally, SWFFocus monitors changes in focus, and will send focus back 
	 *  to the HTML content when a focus wrap is about to occur. This should allow 
	 *  keybaord users to both tab into and out of embedded Flash content.</p>
	 */
	public class SWFFocus extends EventDispatcher 
	{
		private static var _availability:Boolean = ExternalInterface.available;
		private static var _dispatcher:EventDispatcher = new EventDispatcher();
		private static var _instance:SWFFocus = new SWFFocus( SingletonLock );
		private static var _initialized:Boolean = false;
		private var _stage;
		private var _idPrev;
		private var _idNext;
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		public function SWFFocus( lock:Class )
		{
			if ( lock != SingletonLock )   
			{   
				throw new Error( "Invalid Singleton access. Use SWFFocus.init." );   
			}
		}
		
		/**
		 *  
		 *  Initiates swffocus object, and sets callbacks
		 */
		public static function init(stageRef):void 
		{
			var swffocus:SWFFocus = _instance;
			ExternalInterface.addCallback("SWFreFocus", swffocus.reFocus);
			ExternalInterface.addCallback("SWFsetFocusIds", swffocus.setFocusIds);
			if (stageRef && swffocus._stage != stageRef && !_initialized)
			{
				swffocus._stage = stageRef;
				_initialized =  swffocus._initialize();
			}
		};
		
		/**
		 *@private  
		 *  Set event handles and inject JavaScript code
		 */
		private function _initialize():Boolean 
		{
			
			if (_availability && Capabilities.playerType.toLowerCase() == "plugin" && !SWFFocus._initialized) {
				_stage.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, handleFocusChange, false, 0, true);
				/*
				
				The ExternalInterface call executes the following anonymous javascript function
				to create links and script functions to handle focus into and out of swf.
				
				function() {
				var i,j, k, oE,o,pE,p,st,ti,a,d,s,t, cN, prevId, nextId;
				oE=document.getElementsByTagName('object');
				if(oE.length == 0){
				oE=document.getElementsByTagName('embed');
				}
				for(i=0; i<oE.length; i++){
				o=oE[i];
				if( (o.data || o.src) && o.type=='application/x-shockwave-flash'){
				st=true;
				pE=o.getElementsByTagName('param');
				for(j=0; j<pE.length; j++){
				p=pE[j];
				if(p.name.toLowerCase()=='seamlesstabbing'){
				if(p.value.toLowerCase()=='false'){
				st=false;
				}
				break;
				}
				}
				if(o.tagName.toLowerCase() == 'embed'){
				if(o.attributes['seamlesstabbing'] 
				&& o.attributes['seamlesstabbing'].value.toLowerCase()=='false'){
				st=false;
				} else {
				o.setAttribute('seamlesstabbing','true');
				}
				}
				if(st){
				prevId = nextId = '';
				cN = o.className.split(' ');
				for (k = 0; k < cN.length; k++) {
				if (cN[k].indexOf('swfNext-') != -1)
				nextId = cN[k].substr(8);
				else if (cN[k].indexOf('swfPrev-') != -1)
				prevId = cN[k].substr(8); 
				}
				if (prevId == '') {
				prevId = 'beforeswfanchor'+ i;
				a=document.createElement('a');
				a.id='beforeswfanchor'+i;
				a.href='#';
				a.setAttribute('tabindex',-1);
				a.title='Flash start';
				o.parentNode.insertBefore(a,o);
				
				}
				if (nextId == '') {
				nextId = 'afterswfanchor'+ i;
				a=document.createElement('a');
				a.id= nextId;
				a.href='#';
				a.setAttribute('tabindex',-1);
				a.title='Flash end';
				o.parentNode.insertBefore(a,o.nextSibling);
				
				}
				o.SWFsetFocusIds(prevId, nextId);
				if (o.getAttribute('tabindex') <= 0)
				o.setAttribute('tabindex', 0);
				o.addEventListener('focus', function(e){e.target.SWFreFocus();},false);
				}
				}
				}
				}
				*/
				
				ExternalInterface.call("function(){var i,j,k,oE,o,pE,p,st,ti,a,d,s,t,cN,prevId,nextId;oE=document.getElementsByTagName('object');if(oE.length==0){oE=document.getElementsByTagName('embed');} for(i=0;i<oE.length;i++){o=oE[i];if((o.data||o.src)&&o.type=='application/x-shockwave-flash'){st=true;pE=o.getElementsByTagName('param');for(j=0;j<pE.length;j++){p=pE[j];if(p.name.toLowerCase()=='seamlesstabbing'){if(p.value.toLowerCase()=='false'){st=false;} break;}} if(o.tagName.toLowerCase()=='embed'){if(o.attributes['seamlesstabbing']&&o.attributes['seamlesstabbing'].value.toLowerCase()=='false'){st=false;}else{o.setAttribute('seamlesstabbing','true');}} if(st){prevId=nextId='';cN=o.className.split(' ');for(k=0;k<cN.length;k++){if(cN[k].indexOf('swfNext-')!=-1) nextId=cN[k].substr(8);else if(cN[k].indexOf('swfPrev-')!=-1) prevId=cN[k].substr(8);} if(prevId==''){prevId='beforeswfanchor'+i;a=document.createElement('a');a.id='beforeswfanchor'+i;a.href='#';a.setAttribute('tabindex',-1);a.title='Flash start';o.parentNode.insertBefore(a,o);} if(nextId==''){nextId='afterswfanchor'+i;a=document.createElement('a');a.id=nextId;a.href='#';a.setAttribute('tabindex',-1);a.title='Flash end';o.parentNode.insertBefore(a,o.nextSibling);} o.SWFsetFocusIds(prevId,nextId);if(o.getAttribute('tabindex')<=0) o.setAttribute('tabindex',0);o.addEventListener('focus',function(e){e.target.SWFreFocus();},false);}}}}");
			}
			return true;
		}
		
		/**
		 *  @private
		 *  Allow tracing in both browser and Flash debugger
		 */
		private function eTrace(msg):void 
		{
			eCall("function() {if (console) console.log('" + msg +"')}");
			trace(msg);
		}
		
		/**
		 *  @private
		 *  Quick method for ExternalInterface calls
		 */
		private function eCall(functionCall):void
		{
			if(_availability && Capabilities.playerType.toLowerCase()  == "plugin") 
				ExternalInterface.call(functionCall);	
		}
		
		public static function get Instance():SWFFocus{
			return _instance;
		}
		public function tabNext():void{
			eCall("function(){var elem = document.getElementById('"+ _idNext +"'); if (elem) elem.focus();}");
		}
		
		/**
		 *  @private
		 *  Monitors changes in focus, moves focus back to HTML if a focus wrap occurred
		 */		
		private function handleFocusChange(e:FocusEvent):void 
		{	
			
			var a = e.target;
			var b = e.relatedObject;
			if (wrapOccurred(a, b, e.shiftKey)) {
				eTrace("wrap occurred! " + _idNext)
				e.preventDefault();
				eCall("function(){var elem = document.getElementById('"+ (e.shiftKey ? _idPrev : _idNext) +"'); if (elem) elem.focus();}");
			}
		}
		
		/**
		 *  @private
		 *  Compares two Flash elements to dermine whether a focus wrap occurred or not
		 */				
		private function wrapOccurred(a:InteractiveObject, b:InteractiveObject, goingBackwards:Boolean):Boolean 
		{
			var focusIndex1:String = "";
			var focusIndex2:String = "";
			var index:int;
			var tmp:String;
			var tmp2:String;
			var zeros:String = "0000";
			
			if (a.tabIndex == b.tabIndex) 
			{
				// tabindex not explicitly set, or set to the same value. 
				// Use childindex to determine which element comes before the other instead
				while (a != DisplayObject(_stage) && a.parent)
				{
					index = a.parent.getChildIndex(a);
					tmp = index.toString(16);
					if (tmp.length < 4)
					{
						tmp2 = zeros.substring(0, 4 - tmp.length) + tmp;
					}
					focusIndex1 = tmp2 + focusIndex1;
					a = a.parent;
				}
				
				while (b != DisplayObject(_stage) && b.parent)
				{
					index = b.parent.getChildIndex(b);
					tmp = index.toString(16);
					if (tmp.length < 4)
					{
						tmp2 = zeros.substring(0, 4 - tmp.length) + tmp;
					}
					focusIndex2 = tmp2 + focusIndex2;
					b = b.parent;
				}
			}
			else 
			{
				// tabindex explicitly set
				focusIndex1 = a.tabIndex.toString();
				focusIndex2 = b.tabIndex.toString();
			}
			return !goingBackwards ? focusIndex1 >= focusIndex2 : focusIndex1 <= focusIndex2;
		}
		
		/**
		 *  
		 *  Callback function for JavaScript, to be called when the Flash movie object is focused in HTML
		 */				
		public function reFocus():void 
		{
			// perform a hack toprogrammatically refocus the focused Flash element by quickly moving focus 
			// backwards and foward in the Flash tab order (without this the movie object itself would stay
			// focused)
			setTimeout(function() {	
				var fm:FocusManager = new FocusManager(_stage);
				fm.setFocus(fm.getNextFocusManagerComponent(true));
				fm.setFocus(fm.getNextFocusManagerComponent());				
			}, 100);
		}
		
		/**
		 *  
		 *  Callback function for JavaScript, used to set IDs of next and previous 
		 *  elements in the HTML tab order
		 */
		public function setFocusIds(idPrev, idNext):void 
		{
			if (idPrev)
				_idPrev = idPrev;
			if (idNext)
				_idNext = idNext;
		}
	}
}

/**  
 * This is a private class declared outside of the package  
 * that is only accessible to classes inside of the SWFFocus.as  
 * file.  Because of that, no outside code is able to get a  
 * reference to this class to pass to the constructor, which  
 * enables us to prevent outside instantiation.  
 */  
class SingletonLock
{   
} // end class  
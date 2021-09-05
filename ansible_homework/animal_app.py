# -*- coding: utf-8 -*-

from flask import Flask, render_template
from flask.globals import request
import jsonschema
from jsonschema import validate
import emoji

app = Flask(__name__)

hello_pic = '''
D.H., 1991           __gggrgM**M#mggg__
                __wgNN@"B*P""mp""@d#"@N#Nw__
              _g#@0F_a*F#  _*F9m_ ,F9*__9NG#g_
           _mN#F  aM"    #p"    !q@    9NL "9#Qu_
          g#MF _pP"L  _g@"9L_  _g""#__  g"9w_ 0N#p
        _0F jL*"   7_wF     #_gF     9gjF   "bJ  9h_
       j#  gAF    _@NL     _g@#_      J@u_    2#_  #_
      ,FF_#" 9_ _#"  "b_  g@   "hg  _#"  !q_ jF "*_09_
      F N"    #p"      Ng@       `#g"      "w@    "# t
     j p#    g"9_     g@"9_      gP"#_     gF"q    Pb L
     0J  k _@   9g_ j#"   "b_  j#"   "b_ _d"   q_ g  ##
     #F  `NF     "#g"       "Md"       5N#      9W"  j#
     #k  jFb_    g@"q_     _*"9m_     _*"R_    _#Np  J#
     tApjF  9g  J"   9M_ _m"    9%_ _*"   "#  gF  9_jNF
      k`N    "q#       9g@        #gF       ##"    #"j
      `_0q_   #"q_    _&"9p_    _g"`L_    _*"#   jAF,'
       9# "b_j   "b_ g"    *g _gF    9_ g#"  "L_*"qNF
        "b_ "#_    "NL      _B#      _I@     j#" _#"
          NM_0"*g_ j""9u_  gP  q_  _w@ ]_ _g*"F_g@
           "NNh_ !w#_   9#g"    "m*"   _#*" _dN@"
              9##g_0@q__ #"4_  j*"k __*NF_g#@P"
                "9NN#gIPNL_ "b@" _2M"Lg#N@F"
                    ""P@*NN#gEZgNN@#@P""

'''
curl_error = '''Error, try
curl -XPOST -k -d'{"animal":"cow", "sound":"moooo", "count": 3}' http://myvm.localhost/
or
curl -XPOST -k -d'{"animal":"elephant", "sound":"whoooaaa", "count": 5}' http://myvm.localhost/
'''
validation_schema = {
    "type": "object",
    "properties": {
        "animal": {
		"type": "string",
		"minLength": 1,
  		"maxLength": 50
		},
        "sound": {
		"type": "string",
		"minLength": 0,
                "maxLength": 50
		},
        "count": {
		"type": "number",
		"minimum": 0,
  		"exclusiveMaximum": 10000
		}
    },
    "required": ["animal", "sound", "count"]
}


def validate_json(json_data):
    try:
        validate(instance=json_data, schema=validation_schema)
    except jsonschema.exceptions.ValidationError:
        return False
    return True


@app.route("/", methods=['GET', 'POST'])
def main():
    app.logger.info("Host %s", request.host_url)
    app.logger.info("Headers: %s", dict(request.headers))
    if request.method == 'POST':
        app.logger.info("It's POST request")
        request_data = request.get_json(force=True, silent=True)
        app.logger.info('Json data: %s\n', request_data)
        is_valid = validate_json(request_data)
        if is_valid:
            app.logger.info("Json is OK")
            return generate_curl_result(request_data)
        else:
            app.logger.info("Validation Fail")
            return 'wrong json sended \n' + curl_error
    else:
        app.logger.info("It's GET request")
    if "curl" in request.user_agent.string:
        app.logger.info("Curl client, returning hello_pic's image")
        return hello_pic + curl_error + "\n"
    return render_template('game'), 200


@app.errorhandler(404)
def wrong_url(err_arg):
    app.logger.info("Host gets 404 error %s", request.host_url)
    if "curl" in request.user_agent.string:
        return request.host_url + 'ERROR 404 \n '+ curl_error, 404
    else:
        return render_template('404'), 404


def generate_curl_result(request_data):
    result_msg=""
    app.logger.info("Getting some data: %s", request_data)
    animal = str(request_data['animal']).lower()
    sound = str(request_data['sound'])
    count = int(request_data['count'])
    animal_emoj = emoji.emojize(":"+animal+":")
    if animal_emoj == ":"+animal+":":
        app.logger.info("Finded emoji (%s) for (%s)",animal_emoj ,animal)
        animal_res = animal.capitalize()
    else:
        app.logger.info("Cant find  emoji for (%s)" ,animal)
        animal_res = animal_emoj
    app.logger.info(
        "Params for msg look like animal = %s, sound = %s, count = %s", animal, sound, count)
    for i in range(count):
        result_msg += animal_res + " says " + sound + "\n"
    with_love_emoj = emoji.emojize(":green_heart:")
    result_msg += "Made with " + with_love_emoj + "️ by Juri Gogolev\n"
    return result_msg


if __name__ == '__main__':
	app.run(debug=True,port=80)

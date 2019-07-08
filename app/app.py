from flask import *
from jinja2 import Environment, FileSystemLoader
from elasticsearch import Elasticsearch

app = Flask(__name__)
env = Environment(loader=FileSystemLoader('./', encoding='utf8'))
tpl = env.get_template('query.json.j2')
es = Elasticsearch(['elasticsearch'])

@app.route("/", methods=["GET", "POST"])
def search():
    if request.method == "GET":
        return """
        検索ワードを入れる
        <form action="/" method="POST">
        <input name="word"></input>
        </form>"""
    else:
        result = str(request.form['word'])
        json_string = tpl.render({'word': result})
        es_result = es.search(
            index="samples", body=json_string)
        data = [hit['_source'] for hit in es_result['hits']['hits']]
        return render_template(
            'tables.html',
            data=data)


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8888, threaded=True)

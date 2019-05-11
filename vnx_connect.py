import requests
import pygal
from pygal.style import LightColorizedStyle as LCS, LightenStyle as LS

# Github API URL
url = 'https://api.github.com/search/repositories?q=language:python&sort=star'

r = requests.get(url)

response_dicts = r.json()
r_dicts = response_dicts['items']

names, plot_dicts = [], []
for r_dict in r_dicts:
    names.append(r_dict['name'])
    plot_dict = {
        'value': r_dict['stargazers_count'],
        'label': r_dict['description'],
        'xlink': r_dict['html_url']
    }
    plot_dicts.append(plot_dict)

style = LS('#333366', base_style=LCS)
config = pygal.Config()
config.x_label_rotation = 45
config.show_legend = False
config.title_font_size = 24
config.lable_font_size  = 14
config.major_lable_font_size = 18
config.truncate_label = 15
config.show_y_guides = False
config.width = 1000
chart = pygal.Bar(config, style=style)
chart.title = 'Most Starred Python Projects on Github'
chart.x_labels = names
chart.add('', plot_dicts)
chart.render_to_file('python_repos.svg')


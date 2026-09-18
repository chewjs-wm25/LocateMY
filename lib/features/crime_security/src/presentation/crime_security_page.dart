

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/safety_models.dart';
import 'safety_strings.dart';
import 'safety_view_model.dart';
import 'safety_widgets.dart';

final class CrimeSecurityPage extends StatefulWidget {
  final CrimeSecurity crime;
  final ValidLocationReference location;
  final ValidLocationReference? locationB;
  final void Function(ValidLocationReference)? onShowMap;
  final VoidCallback? onPortfolio;
  final void Function(ValidLocationReference)? onAddProperty;

  const CrimeSecurityPage({
    required CrimeSecurity crime,
    required ValidLocationReference location,
    ValidLocationReference? locationB,
    void Function(ValidLocationReference)? onShowMap,
    VoidCallback? onPortfolio,
    void Function(ValidLocationReference)? onAddProperty,
    super.key,
  }) : crime = crime,
       location = location,
       locationB = locationB,
       onShowMap = onShowMap,
       onPortfolio = onPortfolio,
       onAddProperty = onAddProperty;

  @override
  State<CrimeSecurityPage> createState() {
    return _CrimeSecurityPageState();
  }
}

final class _CrimeSecurityPageState extends State<CrimeSecurityPage> {
  late SafetyViewModel _model;

  @override
  void initState() {
    super.initState();

    _model = SafetyViewModel(
      widget.crime,
      widget.location,
      locationB: widget.locationB,
    );

    _model.load();
  }

  @override
  void didUpdateWidget(CrimeSecurityPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.crime != widget.crime ||
        oldWidget.location != widget.location ||
        oldWidget.locationB != widget.locationB) {
      _model.dispose();

      _model = SafetyViewModel(
        widget.crime,
        widget.location,
        locationB: widget.locationB,
      );

      _model.load();
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SafetyStrings s = SafetyStrings(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 28
            ? 104
            : 56,
        title: Text(
          s.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          softWrap: true,
          maxLines: 3,
        ),
        actions: <Widget>[
          if (widget.locationB == null &&
              widget.onShowMap != null &&
              MediaQuery.textScalerOf(context).scale(20) > 28)
            IconButton(
              tooltip: s.text('Main map', '主地图'),
              onPressed: () {
                widget.onShowMap!(widget.location);
              },
              icon: const Icon(Icons.map_outlined),
              color: const Color(0xFF155EEF),
            ),

          if (widget.locationB == null &&
              widget.onShowMap != null &&
              MediaQuery.textScalerOf(context).scale(20) <= 28)
            Tooltip(
              message: s.text('Main map', '主地图'),
              child: TextButton(
                onPressed: () {
                  widget.onShowMap!(widget.location);
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFF155EEF),
                ),
                child: Text(
                  s.text('Main map', '主地图'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (widget.locationB != null)
            IconButton(
              tooltip: s.text('Swap A/B', '交换 A/B'),
              onPressed: () {
                _model.swap();
              },
              icon: const Icon(Icons.swap_horiz),
            ),
        ],
      ),

      body: AnimatedBuilder(
        animation: _model,
        builder: (BuildContext context, Widget? child) {
          final SafetyComparison? comparison = _model.comparison;

          final List<SafetyAnalysis> analyses = <SafetyAnalysis>[];

          if (comparison != null) {
            if (_model.swapped) {
              analyses.addAll(
                <SafetyAnalysis>[
                  comparison.b,
                  comparison.a,
                ],
              );
            } else {
              analyses.addAll(
                <SafetyAnalysis>[
                  comparison.a,
                  comparison.b,
                ],
              );
            }
          } else if (_model.analysis != null) {
            analyses.add(_model.analysis!);
          }

          final SafetyAnalysis? result = _model.analysis;

          final List<Widget> children = <Widget>[];

          if (widget.locationB == null) {
            children.add(
              Text(
                widget.location.displayName ??
                    s.text(
                      'Selected location',
                      '所选地点',
                    ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );

            children.add(
              const SizedBox(height: 4),
            );

            children.add(
              Text(
                '${result?.reportingState ?? '—'} · '
                '${s.text('Reporting state', '统计州口径')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF667085),
                ),
              ),
            );

            children.add(
              const SizedBox(height: 20),
            );
          }

          if (_model.loading) {
            children.add(
              LinearProgressIndicator(
                semanticsLabel: s.text(
                  'Loading crime data',
                  '正在加载治安资料',
                ),
              ),
            );

            children.add(
              const SizedBox(height: 16),
            );
          }

          if (comparison != null) {
            String message = s.text(
              'Not comparable: one side is unavailable.',
              '不可比：一侧资料暂不可用。',
            );

            if (comparison.reason == SafetyComparisonReason.incomplete) {
              message = s.text(
                'Not comparable: partial data.',
                '不可比：资料不完整。',
              );
            }

            if (comparison.reason == SafetyComparisonReason.scopeMismatch) {
              message = s.text(
                'Not comparable: statistical scope differs.',
                '不可比：统计口径不同。',
              );
            }

            if (comparison.difference != null) {
              double difference = comparison.difference!;

              if (_model.swapped) {
                difference = -difference;
              }

              message =
                  'B − A: '
                  '${NumberFormat.decimalPattern(
                    s.zh ? 'zh' : 'en',
                  ).format(difference)}';
            }

            children.add(
              Text(message),
            );

            children.add(
              const SizedBox(height: 16),
            );
          }

          for (int index = 0; index < analyses.length; index++) {
            final SafetyAnalysis result = analyses[index];

            if (comparison != null) {
              String role = 'A';

              if (index == 1) {
                role = 'B';
              }

              children.add(
                Text(
                  '$role · '
                  '${result.location.displayName ?? s.text(
                    'Selected location',
                    '所选地点',
                  )}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );

              children.add(
                Text(
                  '${result.reportingState ?? '—'} · '
                  '${s.text(
                    'Reporting state',
                    '统计州口径',
                  )}',
                ),
              );

              children.add(
                const SizedBox(height: 12),
              );
            }

            children.add(
              SafetyResultCard(
                analysis: result,
              ),
            );

            if (comparison != null &&
                widget.onShowMap != null) {
              children.add(
                TextButton.icon(
                  onPressed: () {
                    widget.onShowMap!(
                      result.location,
                    );
                  },
                  icon: const Icon(
                    Icons.map_outlined,
                  ),
                  label: Text(
                    s.text(
                      'Main map',
                      '主地图',
                    ),
                  ),
                ),
              );
            }

            children.add(
              const SizedBox(height: 20),
            );

            if (result.trends.isNotEmpty) {
              children.add(
                Text(
                  s.text(
                    'Last 5 years',
                    '最近 5 年趋势',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );

              children.add(
                const SizedBox(height: 4),
              );

              children.add(
                Text(
                  s.text(
                    'Filters affect only the trend, not the safety index.',
                    '筛选仅影响趋势图，不改变安全指数',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667085),
                  ),
                ),
              );

              children.add(
                const SizedBox(height: 8),
              );

              
              
              

              final List<Widget> chips = <Widget>[];

              final List<String> keys = <String>[
                'all',
                'assault',
                'property',
              ];

              for (final String key in keys) {
                final List<CrimeYearCount>? series =
                    result.trends[key];

                final int? count =
                    series?.last.count;

                String label =
                    s.category(key);

                if (count != null) {
                  label =
                      '$label '
                      '(${NumberFormat.decimalPattern(
                        s.zh ? 'zh' : 'en',
                      ).format(count)})';
                }

                chips.add(
                  ChoiceChip(
                    label: Text(label),
                    selected:
                        _model.filter == key,
                    onSelected:
                        (bool selected) {
                      if (selected) {
                        _model.select(key);
                      }
                    },
                    shape:
                        const StadiumBorder(),
                    side:
                        BorderSide.none,
                    selectedColor:
                        const Color(
                          0xFF155EEF,
                        ),
                    backgroundColor:
                        Colors.white,
                    labelStyle:
                        TextStyle(
                      fontSize: 13,
                      color:
                          _model.filter ==
                                  key
                              ? Colors.white
                              : const Color(
                                  0xFF172033,
                                ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }

              children.add(
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: chips,
                ),
              );

              
              
              

              final List<
                  PopupMenuEntry<
                      String>> types =
                  <PopupMenuEntry<
                      String>>[
                
                
                
                
                
                
                PopupMenuItem<String>(
                  value: 'all',
                  child: Text(
                    s.text(
                      'None',
                      '无',
                    ),
                  ),
                ),
              ];

              for (final String key
                  in result.trends.keys) {
                if (!key.startsWith(
                  'type:',
                )) {
                  continue;
                }

                String label =
                    s.category(key);

                final int? count =
                    result
                        .trends[key]!
                        .last
                        .count;

                if (count != null) {
                  label =
                      '$label '
                      '(${NumberFormat.decimalPattern(
                        s.zh ? 'zh' : 'en',
                      ).format(count)})';
                }

                types.add(
                  PopupMenuItem<String>(
                    value: key,
                    child: Text(label),
                  ),
                );
              }

              
              
              
              
              
              if (types.length > 1) {
                String selectedTypeLabel =
                    s.text(
                  'None',
                  '无',
                );

                if (_model.filter.startsWith(
                  'type:',
                )) {
                  selectedTypeLabel =
                      s.category(
                    _model.filter,
                  );
                }

                children.add(
                  PopupMenuButton<String>(
                    tooltip: s.text(
                      'Select crime type',
                      '选择犯罪类型',
                    ),

                    
                    
                    onSelected:
                        _model.select,

                    itemBuilder:
                        (BuildContext context) {
                      return types;
                    },

                    child: Container(
                      constraints:
                          const BoxConstraints(
                        minHeight: 48,
                      ),
                      alignment:
                          Alignment.centerLeft,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        '${s.text(
                          'Specific crime type',
                          '具体犯罪类型',
                        )}: '
                        '$selectedTypeLabel ▾',
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF155EEF,
                          ),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }

              children.add(
                const SizedBox(height: 12),
              );

              
              
              

              children.add(
                SafetyTrendCard(
                  points:
                      result.trends[
                              _model
                                  .filter] ??
                          const <
                              CrimeYearCount>[],
                ),
              );

              children.add(
                const SizedBox(height: 20),
              );
            }

            if (result.availability ==
                SafetyAvailability.unavailable) {
              children.add(
                Text(
                  s.failure(
                    result.failure,
                  ),
                ),
              );

              children.add(
                const SizedBox(height: 8),
              );
            }
          }

          children.add(
            TextButton.icon(
              onPressed:
                  _model.loading
                      ? null
                      : () {
                          _model.load(
                            refresh: true,
                          );
                        },
              icon:
                  const Icon(
                Icons.refresh,
              ),
              label:
                  Text(
                s.text(
                  'Retry / refresh',
                  '重试 / 刷新',
                ),
              ),
            ),
          );

          children.add(
            const SizedBox(height: 12),
          );

          children.add(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () {
                    final VoidCallback?
                        action =
                        widget
                            .onPortfolio;

                    if (action != null) {
                      action();
                    } else {
                      _propertySlot(
                        false,
                      );
                    }
                  },
                  child: Text(
                    s.text(
                      'Property portfolio',
                      '房产档案',
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    final void Function(
                      ValidLocationReference,
                    )? action =
                        widget
                            .onAddProperty;

                    if (action != null) {
                      action(
                        widget.location,
                      );
                    } else {
                      _propertySlot(
                        true,
                      );
                    }
                  },
                  child: Text(
                    s.text(
                      'Add property inspection',
                      '新增房产实勘',
                    ),
                  ),
                ),
              ],
            ),
          );

          return ListView(
            padding:
                const EdgeInsets.all(
              16,
            ),
            children: children,
          );
        },
      ),
    );
  }

  void _propertySlot(bool add) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          SafetyStrings(context)
              .text(
            'Property inspection is unavailable in this harness.',
            '此测试入口未接入房产实勘。',
          ),
        ),
      ),
    );
  }
}